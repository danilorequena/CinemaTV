import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct LifetimeStatisticsTests {
    @Test func countsKnownDurationsWithoutInventingMissingValues() {
        let snapshot = LifetimeStatistics.calculate(
            movies: [
                .init(id: 1, title: "A", watchedAt: date("2024-03-02"), runtimeMinutes: 120, genres: ["Drama"], releaseYear: 1999, personalRating: 5),
                .init(id: 2, title: "B", watchedAt: nil, runtimeMinutes: nil, genres: [], releaseYear: nil, personalRating: nil)
            ],
            episodes: [
                .init(showID: 10, showName: "Show", seasonNumber: 1, episodeNumber: 1, watchedAt: date("2024-03-03"), runtimeMinutes: 45),
                .init(showID: 10, showName: "Show", seasonNumber: 1, episodeNumber: 2, watchedAt: nil, runtimeMinutes: nil)
            ],
            shows: [.init(id: 10, name: "Show", firstAirYear: 2020, genres: ["Drama"], status: "Returning Series")]
        )

        #expect(snapshot.movieCount == 2)
        #expect(snapshot.episodeCount == 2)
        #expect(snapshot.totalKnownMinutes == 165)
        #expect(snapshot.knownDurationCount == 2)
        #expect(snapshot.totalItemCount == 4)
        #expect(snapshot.undatedItemCount == 2)
        #expect(snapshot.monthlyTimeline.map(\.watchedCount) == [2])
        #expect(snapshot.monthlyTimeline.first?.year == 2024)
        #expect(snapshot.monthlyTimeline.first?.month == 3)
    }

    @Test func ranksGenresDecadesShowsAndPersonalFavorites() {
        let snapshot = LifetimeStatistics.calculate(
            movies: [
                .init(id: 1, title: "A", watchedAt: nil, runtimeMinutes: 100, genres: ["Drama", "Comedy"], releaseYear: 1998, personalRating: 4),
                .init(id: 2, title: "B", watchedAt: nil, runtimeMinutes: 90, genres: ["Drama"], releaseYear: 1993, personalRating: 5)
            ],
            episodes: [
                .init(showID: 10, showName: "Show", seasonNumber: 1, episodeNumber: 1, watchedAt: nil, runtimeMinutes: 40),
                .init(showID: 10, showName: "Show", seasonNumber: 1, episodeNumber: 2, watchedAt: nil, runtimeMinutes: 40),
                .init(showID: 11, showName: "Other", seasonNumber: 1, episodeNumber: 1, watchedAt: nil, runtimeMinutes: 30)
            ],
            shows: [
                .init(id: 10, name: "Show", firstAirYear: 2010, genres: ["Drama"], status: "Ended"),
                .init(id: 11, name: "Other", firstAirYear: 2020, genres: ["Comedy"], status: "Returning Series")
            ]
        )

        #expect(snapshot.topGenres.first?.name == "Drama")
        #expect(snapshot.topGenres.first?.count == 3)
        #expect(snapshot.topDecades.first?.name == "1990s")
        #expect(snapshot.topDecades.first?.count == 2)
        #expect(snapshot.topShows.map(\.showID) == [10, 11])
        #expect(snapshot.topShows.first?.episodeCount == 2)
        #expect(snapshot.favoriteMovies.map(\.id) == [2, 1])
    }

    @Test func birthPercentageIsOptionalAndRejectsFutureBirthdates() {
        let now = date("2024-01-02")
        #expect(LifetimeStatistics.lifePercentage(totalKnownMinutes: 1_440, birthDate: nil, now: now) == nil)
        #expect(LifetimeStatistics.lifePercentage(totalKnownMinutes: 1_440, birthDate: date("2024-01-03"), now: now) == nil)
        let percentage = LifetimeStatistics.lifePercentage(totalKnownMinutes: 720, birthDate: date("2024-01-01"), now: now)
        #expect(percentage != nil)
        #expect(abs((percentage ?? 0) - 50) < 0.01)
    }

    @Test func shareSummaryNeverContainsBirthDateOrPercentage() {
        let snapshot = LifetimeStatistics.calculate(
            movies: [.init(id: 1, title: "A", watchedAt: nil, runtimeMinutes: 120, genres: ["Drama"], releaseYear: nil, personalRating: nil)],
            episodes: [],
            shows: []
        )
        let share = LifetimeShareSummary(snapshot: snapshot)
        #expect(share.totalKnownMinutes == 120)
        #expect(share.movieCount == 1)
        #expect(share.topGenre == "Drama")
        #expect(Mirror(reflecting: share).children.compactMap(\.label).allSatisfy { !$0.lowercased().contains("birth") && !$0.lowercased().contains("percent") })
    }

    @Test func largeImportedHistoryKeepsUndatedItemsInTotalsAndMilestones() {
        let movies = (1...500).map { id in
            LifetimeMovieRecord(id: id, title: "Movie \(id)", watchedAt: nil, runtimeMinutes: id.isMultiple(of: 2) ? 100 : nil, genres: [], releaseYear: nil, personalRating: nil)
        }
        let episodes = (1...1_100).map { number in
            LifetimeEpisodeRecord(showID: 10, showName: "Long Show", seasonNumber: (number - 1) / 100 + 1, episodeNumber: (number - 1) % 100 + 1, watchedAt: nil, runtimeMinutes: 40)
        }
        let snapshot = LifetimeStatistics.calculate(
            movies: movies,
            episodes: episodes,
            shows: [.init(id: 10, name: "Long Show", firstAirYear: 2010, genres: [], status: "Ended")]
        )
        #expect(snapshot.totalItemCount == 1_600)
        #expect(snapshot.knownDurationCount == 1_350)
        #expect(snapshot.undatedItemCount == 1_600)
        #expect(snapshot.monthlyTimeline.isEmpty)
        #expect(snapshot.topShows.first?.episodeCount == 1_100)
        #expect(snapshot.milestones.contains(.thousandEpisodes))
        #expect(snapshot.milestones.contains(.thirtyDays))
    }

    @Test func duplicateCloudRecordsUseTheOldestKnownWatchDate() {
        let snapshot = LifetimeStatistics.calculate(
            movies: [
                .init(id: 1, title: "A", watchedAt: date("2024-01-01"), runtimeMinutes: 100, genres: [], releaseYear: nil, personalRating: nil),
                .init(id: 1, title: "A", watchedAt: date("2023-01-01"), runtimeMinutes: 100, genres: [], releaseYear: nil, personalRating: nil)
            ],
            episodes: [
                .init(showID: 10, showName: "S", seasonNumber: 1, episodeNumber: 1, watchedAt: date("2024-02-01"), runtimeMinutes: 40),
                .init(showID: 10, showName: "S", seasonNumber: 1, episodeNumber: 1, watchedAt: date("2023-02-01"), runtimeMinutes: 40)
            ],
            shows: [.init(id: 10, name: "S", firstAirYear: nil, genres: [], status: nil)]
        )
        #expect(snapshot.totalItemCount == 2)
        #expect(snapshot.monthlyTimeline.map(\.year) == [2023, 2023])
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value + "T12:00:00Z")!
    }
}
