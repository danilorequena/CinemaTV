import Foundation
import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct LibraryImportWriterTests {
    @Test func watchlistDeduplicatesWithinTypeButKeepsSameIDAcrossTypes() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let movie = item(id: 42, title: "Movie 42", type: .movie)
        let show = item(id: 42, title: "Show 42", type: .tvShow)
        let writer = makeWriter(
            container: container,
            movies: [42: movieDetails(id: 42, title: "Movie 42")],
            shows: [42: showDetails(id: 42, title: "Show 42")]
        )

        let report = try await writer.save([movie, movie, show], destination: .watchlist)

        #expect(report.added.map(\.mediaType) == [.movie, .tvShow])
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<MoviesToWatch>()) == 1)
        let storedShow = try #require(try context.fetch(FetchDescriptor<TVShowWatchingModel>()).first)
        #expect(storedShow.nextEpisodeSeason == 1)
        #expect(storedShow.nextEpisodeNumber == 1)
    }

    @Test func watchlistImportPreservesAlreadyWatchedMovieAndDate() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let watchedAt = Date(timeIntervalSince1970: 1_600_000_000)
        let context = ModelContext(container)
        context.insert(MoviesWatched(id: 7, name: "Existing", watchedAt: watchedAt))
        try context.save()
        let writer = makeWriter(
            container: container,
            movies: [7: movieDetails(id: 7, title: "Existing")]
        )

        let report = try await writer.save([
            item(id: 7, title: "Existing", type: .movie)
        ], destination: .watchlist)

        #expect(report.unchanged.map(\.id) == [7])
        let verification = ModelContext(container)
        #expect(try verification.fetch(FetchDescriptor<MoviesToWatch>()).isEmpty)
        #expect(try verification.fetch(FetchDescriptor<MoviesWatched>()).first?.watchedAt == watchedAt)
    }

    @Test func watchedMoviesWithUnknownOrFutureFullDatesDoNotMutate() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let unknown = item(id: 1, title: "Unknown", type: .movie)
        let future = item(id: 2, title: "Future", type: .movie)
        let writer = makeWriter(
            container: container,
            movies: [
                1: movieDetails(id: 1, title: "Unknown", releaseDate: nil),
                2: movieDetails(id: 2, title: "Future", releaseDate: "2999-01-01")
            ]
        )

        let report = try await writer.save([unknown, future], destination: .watched)

        #expect(report.skipped.map(\.item.id) == [1, 2])
        #expect(try ModelContext(container).fetch(FetchDescriptor<MoviesWatched>()).isEmpty)
    }

    @Test func watchedShowMarksOnlyKnownPastEpisodesAndExcludesSpecials() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let show = item(id: 10, title: "A Show", type: .tvShow)
        let writer = makeWriter(
            container: container,
            shows: [10: showDetails(id: 10, title: "A Show", includeSpecials: true)],
            seasons: [
                SeasonKey(showID: 10, season: 1): SeasonDetails(
                    id: "season-1",
                    name: "Season 1",
                    seasonNumber: 1,
                    episodes: [
                        episode(id: 101, number: 1, airDate: "2020-01-01"),
                        episode(id: 102, number: 2, airDate: "2999-01-01"),
                        episode(id: 103, number: 3, airDate: nil)
                    ]
                )
            ]
        )

        let report = try await writer.save([show], destination: .watched)

        #expect(report.added.map(\.id) == [10])
        let stored = try #require(try ModelContext(container)
            .fetch(FetchDescriptor<TVShowWatchingModel>()).first)
        let episodes = (stored.seasons ?? []).flatMap { $0.episodes ?? [] }
        #expect(episodes.compactMap(\.episodeNumber) == [1])
        #expect(episodes.first?.watchedAt == nil)
    }

    @Test func seasonFailureOccursBeforeAnyShowMutation() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let details = showDetails(id: 20, title: "Two Seasons", seasonCount: 2)
        let seasonOne = SeasonDetails(
            id: "season-1",
            name: "Season 1",
            seasonNumber: 1,
            episodes: [episode(id: 1, number: 1, airDate: "2020-01-01")]
        )
        let writer = LibraryImportWriter(
            container: container,
            fetchMovieDetails: { _ in throw WriterTestError.missingFixture },
            fetchTVShowDetails: { _ in details },
            fetchSeasonDetails: { _, season in
                if season == 2 { throw WriterTestError.network }
                return seasonOne
            }
        )

        let report = try await writer.save([
            item(id: 20, title: "Two Seasons", type: .tvShow)
        ], destination: .watched)

        #expect(report.failed.map(\.item.id) == [20])
        #expect(try ModelContext(container).fetch(FetchDescriptor<TVShowWatchingModel>()).isEmpty)
    }

    @Test func watchedShowRetainsPriorProgressAndDatesWhileAddingPastEpisodes() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let watchedAt = Date(timeIntervalSince1970: 1_650_000_000)
        let dateAdded = Date(timeIntervalSince1970: 1_600_000_000)
        let context = ModelContext(container)
        let show = TVShowWatchingModel(id: 30, name: "Existing", dateAdded: dateAdded)
        let season = SeasonSD(id: 301, episodeCount: 3, name: "Season 1", seasonNumber: 1, tvShow: show)
        context.insert(show)
        context.insert(season)
        context.insert(EpisodeSD(
            id: 3011,
            airDate: "2020-01-01",
            episodeNumber: 1,
            name: "Episode 1",
            seasonNumber: 1,
            showID: 30,
            watchedAt: watchedAt,
            season: season
        ))
        show.lastActivityAt = watchedAt
        try context.save()

        let details = showDetails(id: 30, title: "Existing")
        let fetchedSeason = SeasonDetails(
            id: "season-1",
            name: "Season 1",
            seasonNumber: 1,
            episodes: [
                episode(id: 3011, number: 1, airDate: "2020-01-01"),
                episode(id: 3012, number: 2, airDate: "2021-01-01"),
                episode(id: 3013, number: 3, airDate: "2999-01-01")
            ]
        )
        let writer = makeWriter(
            container: container,
            shows: [30: details],
            seasons: [SeasonKey(showID: 30, season: 1): fetchedSeason]
        )

        _ = try await writer.save([
            item(id: 30, title: "Existing", type: .tvShow)
        ], destination: .watched)

        let stored = try #require(try ModelContext(container)
            .fetch(FetchDescriptor<TVShowWatchingModel>()).first)
        let episodes = (stored.seasons ?? []).flatMap { $0.episodes ?? [] }
        #expect(Set(episodes.compactMap(\.episodeNumber)) == [1, 2])
        #expect(episodes.first { $0.episodeNumber == 1 }?.watchedAt == watchedAt)
        #expect(episodes.first { $0.episodeNumber == 2 }?.watchedAt == nil)
        #expect(stored.lastActivityAt == watchedAt)
        #expect(stored.dateAdded == dateAdded)
    }

    @Test func cancellationAfterACommitReturnsAccuratePartialReport() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let first = item(id: 1, title: "First", type: .movie)
        let second = item(id: 2, title: "Second", type: .movie)
        let firstDetails = movieDetails(id: 1, title: "First")
        let writer = LibraryImportWriter(
            container: container,
            fetchMovieDetails: { id in
                guard id == 1 else { throw CancellationError() }
                return firstDetails
            },
            fetchTVShowDetails: { _ in throw WriterTestError.missingFixture },
            fetchSeasonDetails: { _, _ in throw WriterTestError.missingFixture }
        )

        let report = try await writer.save([first, second], destination: .watchlist)

        #expect(report.added.map(\.id) == [1])
        #expect(report.failed.map(\.item.id) == [2])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<MoviesToWatch>()) == 1)
    }

    @Test func cancellationBeforeHydrationWritesNothing() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let writer = makeWriter(
            container: container,
            movies: [5: movieDetails(id: 5, title: "Canceled")]
        )
        let task = Task { @MainActor in
            try await writer.save([
                item(id: 5, title: "Canceled", type: .movie)
            ], destination: .watchlist)
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
        #expect(try ModelContext(container).fetch(FetchDescriptor<MoviesToWatch>()).isEmpty)
    }

    @Test func retryIsIdempotent() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let movie = item(id: 88, title: "Retry", type: .movie)
        let writer = makeWriter(
            container: container,
            movies: [88: movieDetails(id: 88, title: "Retry")]
        )

        let first = try await writer.save([movie], destination: .watchlist)
        let second = try await writer.save([movie], destination: .watchlist)

        #expect(first.added.map(\.id) == [88])
        #expect(second.unchanged.map(\.id) == [88])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<MoviesToWatch>()) == 1)
    }

    private func makeWriter(
        container: ModelContainer,
        movies: [Int: MovieDetails] = [:],
        shows: [Int: TVShowDetails] = [:],
        seasons: [SeasonKey: SeasonDetails] = [:]
    ) -> LibraryImportWriter {
        LibraryImportWriter(
            container: container,
            fetchMovieDetails: { id in
                guard let details = movies[id] else { throw WriterTestError.missingFixture }
                return details
            },
            fetchTVShowDetails: { id in
                guard let details = shows[id] else { throw WriterTestError.missingFixture }
                return details
            },
            fetchSeasonDetails: { id, season in
                guard let details = seasons[SeasonKey(showID: id, season: season)] else {
                    throw WriterTestError.missingFixture
                }
                return details
            },
            now: { Date(timeIntervalSince1970: 1_800_000_000) }
        )
    }

    private func item(id: Int, title: String, type: MediaItem.MediaType) -> MediaItem {
        MediaItem(
            id: id,
            title: title,
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: nil,
            mediaType: type
        )
    }

    private func movieDetails(
        id: Int,
        title: String,
        releaseDate: String? = "2020-01-01"
    ) -> MovieDetails {
        MovieDetails(
            id: id,
            title: title,
            originalTitle: nil,
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: releaseDate,
            runtime: nil,
            voteAverage: nil,
            voteCount: nil,
            tagline: nil,
            genres: nil,
            status: nil
        )
    }

    private func showDetails(
        id: Int,
        title: String,
        seasonCount: Int = 1,
        includeSpecials: Bool = false
    ) -> TVShowDetails {
        var summaries = (1...seasonCount).map {
            SeasonSummary(
                id: id * 10 + $0,
                name: "Season \($0)",
                seasonNumber: $0,
                episodeCount: 3,
                airDate: "2020-01-01"
            )
        }
        if includeSpecials {
            summaries.insert(SeasonSummary(id: 1, name: "Specials", seasonNumber: 0), at: 0)
        }
        return TVShowDetails(
            id: id,
            name: title,
            firstAirDate: "2020-01-01",
            numberOfSeasons: seasonCount,
            numberOfEpisodes: seasonCount * 3,
            seasons: summaries
        )
    }

    private func episode(id: Int, number: Int, airDate: String?) -> EpisodeSummary {
        EpisodeSummary(
            id: id,
            name: "Episode \(number)",
            episodeNumber: number,
            seasonNumber: 1,
            airDate: airDate
        )
    }
}

private struct SeasonKey: Hashable, Sendable {
    let showID: Int
    let season: Int
}

private enum WriterTestError: Error {
    case missingFixture
    case network
}
