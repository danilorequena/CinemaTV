import Foundation
import SwiftData

@MainActor
public final class LibraryImportWriter {
    private let container: ModelContainer
    private let fetchMovieDetails: @Sendable (Int) async throws -> MovieDetails
    private let fetchTVShowDetails: @Sendable (Int) async throws -> TVShowDetails
    private let fetchSeasonDetails: @Sendable (Int, Int) async throws -> SeasonDetails
    private let now: @Sendable () -> Date

    public init(container: ModelContainer, client: TMDBClient) {
        self.container = container
        fetchMovieDetails = { id in
            try await client.fetch(.movieDetail(id: id))
        }
        fetchTVShowDetails = { id in
            try await client.fetch(.tvShowDetail(id: id))
        }
        fetchSeasonDetails = { id, season in
            try await client.fetch(.tvShowSeason(id: id, season: season))
        }
        now = { .now }
    }

    init(
        container: ModelContainer,
        fetchMovieDetails: @escaping @Sendable (Int) async throws -> MovieDetails,
        fetchTVShowDetails: @escaping @Sendable (Int) async throws -> TVShowDetails,
        fetchSeasonDetails: @escaping @Sendable (Int, Int) async throws -> SeasonDetails,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.container = container
        self.fetchMovieDetails = fetchMovieDetails
        self.fetchTVShowDetails = fetchTVShowDetails
        self.fetchSeasonDetails = fetchSeasonDetails
        self.now = now
    }

    public func save(
        _ items: [MediaItem],
        destination: LibraryImportDestination
    ) async throws -> LibraryImportReport {
        var report = MutableReport()
        let uniqueItems = deduplicated(items)

        for (index, item) in uniqueItems.enumerated() {
            if Task.isCancelled {
                return try cancellationResult(
                    report: report,
                    remaining: Array(uniqueItems[index...])
                )
            }

            do {
                let hydrated = try await hydrate(item, destination: destination)
                if Task.isCancelled {
                    return try cancellationResult(
                        report: report,
                        remaining: Array(uniqueItems[index...])
                    )
                }
                try write(hydrated, destination: destination, report: &report)
            } catch is CancellationError {
                return try cancellationResult(
                    report: report,
                    remaining: Array(uniqueItems[index...])
                )
            } catch {
                report.failed.append(LibraryImportProblem(
                    item: item,
                    message: error.localizedDescription
                ))
            }
        }
        return report.value
    }

    private func cancellationResult(
        report: MutableReport,
        remaining: [MediaItem]
    ) throws -> LibraryImportReport {
        guard report.hasCompletedItems else { throw CancellationError() }
        var partial = report
        let message = String(localized: "Import canceled.", bundle: .module)
        partial.failed.append(contentsOf: remaining.map {
            LibraryImportProblem(item: $0, message: message)
        })
        return partial.value
    }

    private func hydrate(
        _ item: MediaItem,
        destination: LibraryImportDestination
    ) async throws -> HydratedItem {
        switch item.mediaType {
        case .movie:
            return .movie(try await fetchMovieDetails(item.id))
        case .tvShow:
            let details = try await fetchTVShowDetails(item.id)
            guard destination == .watched else {
                return .tvShow(details, [])
            }
            var seasons: [SeasonDetails] = []
            for summary in (details.seasons ?? []) where summary.seasonNumber > 0 {
                try Task.checkCancellation()
                seasons.append(try await fetchSeasonDetails(details.id, summary.seasonNumber))
            }
            return .tvShow(details, seasons)
        case .person:
            return .unsupported(item)
        }
    }

    private func write(
        _ hydrated: HydratedItem,
        destination: LibraryImportDestination,
        report: inout MutableReport
    ) throws {
        switch hydrated {
        case .unsupported(let item):
            report.skipped.append(LibraryImportProblem(
                item: item,
                message: String(localized: "Only movies and TV shows can be imported.", bundle: .module)
            ))

        case .movie(let details):
            try writeMovie(details, destination: destination, report: &report)

        case .tvShow(let details, let seasons):
            try writeTVShow(details, seasons: seasons, destination: destination, report: &report)
        }
    }

    private func writeMovie(
        _ details: MovieDetails,
        destination: LibraryImportDestination,
        report: inout MutableReport
    ) throws {
        let item = details.mediaItem
        let context = makeContext()

        do {
            let pending = try context.fetch(FetchDescriptor<MoviesToWatch>())
                .first { $0.id == Int64(item.id) }
            let watched = try context.fetch(FetchDescriptor<MoviesWatched>())
                .first { $0.id == Int64(item.id) }

            switch destination {
            case .watchlist:
                guard pending == nil, watched == nil else {
                    report.unchanged.append(item)
                    return
                }
                let nextIndex = (try context.fetch(FetchDescriptor<MoviesToWatch>())
                    .compactMap(\.sortIndex).max() ?? -1) + 1
                context.insert(MoviesToWatch(
                    id: Int64(item.id),
                    counter: item.voteAverage,
                    name: item.title,
                    overview: item.overview,
                    profilePath: item.posterPath,
                    sortIndex: nextIndex,
                    dateAdded: now(),
                    releaseDate: item.releaseDate
                ))

            case .watched:
                if watched != nil {
                    report.unchanged.append(item)
                    return
                }
                guard hasKnownPassedDate(item.releaseDate) else {
                    report.skipped.append(LibraryImportProblem(
                        item: item,
                        message: String(localized: "The movie has no past release date.", bundle: .module)
                    ))
                    return
                }
                if let pending { context.delete(pending) }
                context.insert(MoviesWatched(
                    counter: item.voteAverage,
                    id: Int64(item.id),
                    name: item.title,
                    overview: item.overview,
                    profilePath: item.posterPath,
                    watchedAt: nil
                ))
            }

            try context.save()
            report.added.append(item)
        } catch {
            context.rollback()
            throw error
        }
    }

    private func writeTVShow(
        _ details: TVShowDetails,
        seasons: [SeasonDetails],
        destination: LibraryImportDestination,
        report: inout MutableReport
    ) throws {
        let item = details.mediaItem
        let context = makeContext()

        do {
            let existing = try context.fetch(FetchDescriptor<TVShowWatchingModel>())
                .first { $0.id == details.id }
            let legacyWatched = try context.fetch(FetchDescriptor<TVShowWatchedModel>())
                .first { $0.id == details.id }

            if destination == .watchlist {
                guard existing == nil, legacyWatched == nil else {
                    report.unchanged.append(item)
                    return
                }
                let show = try insertShow(details, in: context)
                recomputeCaches(for: show, seasonDetails: [])
                try context.save()
                report.added.append(item)
                return
            }

            if legacyWatched != nil {
                report.unchanged.append(item)
                return
            }

            let aired = airedEpisodes(in: seasons)
            let priorWatchedCount = existing.map(watchedEpisodeCount) ?? 0
            let newEpisodeCount = aired.reduce(into: 0) { count, pair in
                let watched = Set(existingSeason(in: existing, number: pair.season.seasonNumber)?
                    .episodes?.compactMap(\.episodeNumber) ?? [])
                count += pair.episodes.filter { !watched.contains($0.episodeNumber) }.count
            }

            guard priorWatchedCount > 0 || newEpisodeCount > 0 else {
                report.skipped.append(LibraryImportProblem(
                    item: item,
                    message: String(localized: "The TV show has no aired regular episodes.", bundle: .module)
                ))
                return
            }

            let show = try existing ?? insertShow(details, in: context)
            if existing != nil {
                refresh(show, from: details, seasonDetails: seasons, in: context)
            }
            insertMissingEpisodes(aired, show: show, in: context)
            recomputeCaches(for: show, seasonDetails: seasons)
            try context.save()

            if existing == nil {
                report.added.append(item)
            } else if newEpisodeCount > 0 {
                report.added.append(item)
            } else {
                report.unchanged.append(item)
            }
        } catch {
            context.rollback()
            throw error
        }
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func insertShow(
        _ details: TVShowDetails,
        in context: ModelContext
    ) throws -> TVShowWatchingModel {
        let nextIndex = (try context.fetch(FetchDescriptor<TVShowWatchingModel>())
            .compactMap(\.sortIndex).max() ?? -1) + 1
        let show = TVShowWatchingModel(
            id: details.id,
            name: details.name,
            overview: details.overview,
            imagePath: details.posterPath,
            voteAverage: details.voteAverage,
            firstAirDate: details.firstAirDate,
            totalEpisodes: regularSummaries(details).reduce(0) { $0 + ($1.episodeCount ?? 0) },
            dateAdded: now(),
            sortIndex: nextIndex
        )
        context.insert(show)
        for summary in regularSummaries(details) {
            context.insert(SeasonSD(
                id: summary.id,
                airDate: summary.airDate,
                episodeCount: summary.episodeCount,
                name: summary.name,
                overview: summary.overview,
                posterPath: summary.posterPath,
                seasonNumber: summary.seasonNumber,
                tvShow: show
            ))
        }
        updateUpcoming(for: show, from: details)
        return show
    }

    private func refresh(
        _ show: TVShowWatchingModel,
        from details: TVShowDetails,
        seasonDetails: [SeasonDetails],
        in context: ModelContext
    ) {
        show.name = details.name
        show.overview = details.overview
        show.imagePath = details.posterPath
        show.voteAverage = details.voteAverage
        show.firstAirDate = details.firstAirDate

        for summary in regularSummaries(details) {
            if let season = existingSeason(in: show, number: summary.seasonNumber) {
                season.id = summary.id
                season.airDate = summary.airDate
                season.episodeCount = summary.episodeCount
                season.name = summary.name
                season.overview = summary.overview
                season.posterPath = summary.posterPath
            } else {
                context.insert(SeasonSD(
                    id: summary.id,
                    airDate: summary.airDate,
                    episodeCount: summary.episodeCount,
                    name: summary.name,
                    overview: summary.overview,
                    posterPath: summary.posterPath,
                    seasonNumber: summary.seasonNumber,
                    tvShow: show
                ))
            }
        }

        let fetchedCounts = Dictionary(uniqueKeysWithValues: seasonDetails.map {
            ($0.seasonNumber, $0.episodes.count)
        })
        show.totalEpisodes = regularSummaries(details).reduce(0) { count, summary in
            count + (fetchedCounts[summary.seasonNumber] ?? summary.episodeCount ?? 0)
        }
        updateUpcoming(for: show, from: details)
    }

    private func airedEpisodes(
        in seasons: [SeasonDetails]
    ) -> [(season: SeasonDetails, episodes: [EpisodeSummary])] {
        let currentDate = now()
        return seasons
            .filter { $0.seasonNumber > 0 }
            .sorted { $0.seasonNumber < $1.seasonNumber }
            .map { season in
                let episodes = season.episodes.filter {
                    ($0.seasonNumber ?? season.seasonNumber) > 0
                        && hasKnownPassedDate($0.airDate, asOf: currentDate)
                }
                return (season, episodes)
            }
    }

    private func insertMissingEpisodes(
        _ aired: [(season: SeasonDetails, episodes: [EpisodeSummary])],
        show: TVShowWatchingModel,
        in context: ModelContext
    ) {
        for pair in aired {
            guard let season = existingSeason(in: show, number: pair.season.seasonNumber) else { continue }
            let watched = Set((season.episodes ?? []).compactMap(\.episodeNumber))
            for episode in pair.episodes where !watched.contains(episode.episodeNumber) {
                context.insert(EpisodeSD(
                    id: episode.id,
                    airDate: episode.airDate,
                    episodeNumber: episode.episodeNumber,
                    name: episode.name,
                    overview: episode.overview,
                    runtime: episode.runtime,
                    seasonNumber: pair.season.seasonNumber,
                    showID: show.id,
                    stillPath: episode.stillPath,
                    voteAverage: episode.voteAverage,
                    watchedAt: nil,
                    season: season
                ))
            }
            season.episodeCount = pair.season.episodes.count
        }
        show.totalEpisodes = regularSeasons(show).reduce(0) { $0 + ($1.episodeCount ?? 0) }
    }

    private func recomputeCaches(
        for show: TVShowWatchingModel,
        seasonDetails: [SeasonDetails]
    ) {
        let oldActivity = show.lastActivityAt
        let episodeActivity = regularSeasons(show)
            .flatMap { $0.episodes ?? [] }
            .filter { !$0.isDeleted }
            .compactMap(\.watchedAt)
            .max()
        show.lastActivityAt = [oldActivity, episodeActivity].compactMap { $0 }.max()

        let detailsBySeason = Dictionary(uniqueKeysWithValues: seasonDetails.map {
            ($0.seasonNumber, $0)
        })
        for season in regularSeasons(show) {
            guard let seasonNumber = season.seasonNumber else { continue }
            let watched = Set((season.episodes ?? [])
                .filter { !$0.isDeleted }
                .compactMap(\.episodeNumber))
            let total = season.episodeCount ?? 0
            guard total > 0 else { continue }
            for episodeNumber in 1...total where !watched.contains(episodeNumber) {
                let episode = detailsBySeason[seasonNumber]?.episodes
                    .first { $0.episodeNumber == episodeNumber }
                show.nextEpisodeSeason = seasonNumber
                show.nextEpisodeNumber = episodeNumber
                show.nextEpisodeName = episode?.name
                show.nextEpisodeStillPath = episode?.stillPath
                return
            }
        }
        show.nextEpisodeSeason = nil
        show.nextEpisodeNumber = nil
        show.nextEpisodeName = nil
        show.nextEpisodeStillPath = nil
    }

    private func updateUpcoming(for show: TVShowWatchingModel, from details: TVShowDetails) {
        show.upcomingAirDate = details.nextEpisodeToAir?.airDate
        show.upcomingSeason = details.nextEpisodeToAir?.seasonNumber
        show.upcomingEpisode = details.nextEpisodeToAir?.episodeNumber
        show.upcomingEpisodeName = details.nextEpisodeToAir?.name
        show.status = details.status
    }

    private func regularSummaries(_ details: TVShowDetails) -> [SeasonSummary] {
        (details.seasons ?? []).filter { $0.seasonNumber > 0 }
    }

    private func regularSeasons(_ show: TVShowWatchingModel) -> [SeasonSD] {
        (show.seasons ?? [])
            .filter { ($0.seasonNumber ?? 0) > 0 && !$0.isDeleted }
            .sorted { ($0.seasonNumber ?? 0) < ($1.seasonNumber ?? 0) }
    }

    private func existingSeason(
        in show: TVShowWatchingModel?,
        number: Int
    ) -> SeasonSD? {
        (show?.seasons ?? []).first { $0.seasonNumber == number && !$0.isDeleted }
    }

    private func watchedEpisodeCount(_ show: TVShowWatchingModel) -> Int {
        regularSeasons(show).reduce(0) {
            $0 + ($1.episodes ?? []).filter { !$0.isDeleted }.count
        }
    }

    private func hasKnownPassedDate(_ date: String?) -> Bool {
        hasKnownPassedDate(date, asOf: now())
    }

    private func hasKnownPassedDate(_ date: String?, asOf currentDate: Date) -> Bool {
        guard let date,
              let parsed = try? Date(date, strategy: .iso8601.year().month().day())
        else { return false }
        return parsed <= currentDate
    }

    private func deduplicated(_ items: [MediaItem]) -> [MediaItem] {
        var seen = Set<WriterMediaIdentity>()
        return items.filter { seen.insert(WriterMediaIdentity($0)).inserted }
    }
}

private enum HydratedItem {
    case movie(MovieDetails)
    case tvShow(TVShowDetails, [SeasonDetails])
    case unsupported(MediaItem)
}

private struct WriterMediaIdentity: Hashable {
    let id: Int
    let type: MediaItem.MediaType

    init(_ item: MediaItem) {
        id = item.id
        type = item.mediaType
    }
}

private struct MutableReport {
    var added: [MediaItem] = []
    var unchanged: [MediaItem] = []
    var skipped: [LibraryImportProblem] = []
    var failed: [LibraryImportProblem] = []

    var hasCompletedItems: Bool {
        !added.isEmpty || !unchanged.isEmpty || !skipped.isEmpty || !failed.isEmpty
    }

    var value: LibraryImportReport {
        LibraryImportReport(
            added: added,
            unchanged: unchanged,
            skipped: skipped,
            failed: failed
        )
    }
}
