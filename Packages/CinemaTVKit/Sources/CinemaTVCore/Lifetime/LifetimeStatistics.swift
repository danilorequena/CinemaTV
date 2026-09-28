import Foundation

public struct LifetimeMovieRecord: Sendable, Equatable {
    public let id: Int
    public let title: String
    public let watchedAt: Date?
    public let runtimeMinutes: Int?
    public let genres: [String]
    public let releaseYear: Int?
    public let personalRating: Double?

    public init(id: Int, title: String, watchedAt: Date?, runtimeMinutes: Int?, genres: [String], releaseYear: Int?, personalRating: Double?) {
        self.id = id
        self.title = title
        self.watchedAt = watchedAt
        self.runtimeMinutes = runtimeMinutes
        self.genres = genres
        self.releaseYear = releaseYear
        self.personalRating = personalRating
    }
}

public struct LifetimeEpisodeRecord: Sendable, Equatable {
    public let showID: Int
    public let showName: String
    public let seasonNumber: Int
    public let episodeNumber: Int
    public let watchedAt: Date?
    public let runtimeMinutes: Int?

    public init(showID: Int, showName: String, seasonNumber: Int, episodeNumber: Int, watchedAt: Date?, runtimeMinutes: Int?) {
        self.showID = showID
        self.showName = showName
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.watchedAt = watchedAt
        self.runtimeMinutes = runtimeMinutes
    }
}

public struct LifetimeShowRecord: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let firstAirYear: Int?
    public let genres: [String]
    public let status: String?

    public init(id: Int, name: String, firstAirYear: Int?, genres: [String], status: String?) {
        self.id = id
        self.name = name
        self.firstAirYear = firstAirYear
        self.genres = genres
        self.status = status
    }
}

public struct LifetimeTimelineBucket: Sendable, Equatable, Identifiable {
    public let year: Int
    public let month: Int
    public let watchedCount: Int
    public var id: String { "\(year)-\(month)" }

    public init(year: Int, month: Int, watchedCount: Int) {
        self.year = year
        self.month = month
        self.watchedCount = watchedCount
    }
}

public struct LifetimeRanking: Sendable, Equatable, Identifiable {
    public let name: String
    public let count: Int
    public var id: String { name }
}

public struct LifetimeShowRanking: Sendable, Equatable, Identifiable {
    public let showID: Int
    public let name: String
    public let episodeCount: Int
    public var id: Int { showID }
}

public struct LifetimeFavoriteMovie: Sendable, Equatable, Identifiable {
    public let id: Int
    public let title: String
    public let rating: Double
}

public enum LifetimeMilestone: String, Sendable, CaseIterable, Identifiable {
    case firstMovie, tenMovies, hundredMovies, firstEpisode, hundredEpisodes, thousandEpisodes, hundredHours, thirtyDays
    public var id: String { rawValue }
}

public struct LifetimeSnapshot: Sendable, Equatable {
    public let movieCount: Int
    public let episodeCount: Int
    public let totalKnownMinutes: Int
    public let knownDurationCount: Int
    public let undatedItemCount: Int
    public let monthlyTimeline: [LifetimeTimelineBucket]
    public let topGenres: [LifetimeRanking]
    public let topDecades: [LifetimeRanking]
    public let topShows: [LifetimeShowRanking]
    public let favoriteMovies: [LifetimeFavoriteMovie]
    public let milestones: [LifetimeMilestone]

    public var totalItemCount: Int { movieCount + episodeCount }
    public var durationCoverage: Double {
        totalItemCount == 0 ? 0 : Double(knownDurationCount) / Double(totalItemCount)
    }
}

/// Only the fields represented here may be exported in Lifetime's share card.
public struct LifetimeShareSummary: Sendable, Equatable {
    public let totalKnownMinutes: Int
    public let movieCount: Int
    public let episodeCount: Int
    public let knownDurationCount: Int
    public let totalItemCount: Int
    public let topGenre: String?

    public init(snapshot: LifetimeSnapshot) {
        totalKnownMinutes = snapshot.totalKnownMinutes
        movieCount = snapshot.movieCount
        episodeCount = snapshot.episodeCount
        knownDurationCount = snapshot.knownDurationCount
        totalItemCount = snapshot.totalItemCount
        topGenre = snapshot.topGenres.first?.name
    }
}

public enum LifetimeStatistics {
    public static func calculate(
        movies: [LifetimeMovieRecord],
        episodes: [LifetimeEpisodeRecord],
        shows: [LifetimeShowRecord]
    ) -> LifetimeSnapshot {
        // CloudKit can briefly present duplicate semantic records after a merge.
        let movies = Dictionary(grouping: movies, by: \.id).values.compactMap(mergeMovies)
        let episodes = Dictionary(grouping: episodes, by: { "\($0.showID)-\($0.seasonNumber)-\($0.episodeNumber)" }).values.compactMap(mergeEpisodes)
        let showsByID = Dictionary(grouping: shows, by: \.id).compactMapValues(\.first)

        let minutes = (movies.map(\.runtimeMinutes) + episodes.map(\.runtimeMinutes)).compactMap { value in
            guard let value, value > 0 else { return nil as Int? }
            return value
        }
        let dates = movies.map(\.watchedAt) + episodes.map(\.watchedAt)
        let dated = dates.compactMap { $0 }
        let calendar = Calendar(identifier: .gregorian)
        let months = Dictionary(grouping: dated) { date in
            let components = calendar.dateComponents([.year, .month], from: date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }
        let timeline = months.compactMap { _, values -> LifetimeTimelineBucket? in
            guard let first = values.first else { return nil }
            let components = calendar.dateComponents([.year, .month], from: first)
            guard let year = components.year, let month = components.month else { return nil }
            return LifetimeTimelineBucket(year: year, month: month, watchedCount: values.count)
        }.sorted { ($0.year, $0.month) < ($1.year, $1.month) }

        let watchedShowIDs = Set(episodes.map(\.showID))
        let watchedShows = watchedShowIDs.compactMap { showsByID[$0] }
        var genreCounts: [String: Int] = [:]
        for genres in movies.map(\.genres) + watchedShows.map(\.genres) {
            for name in Set(genres.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }).filter({ !$0.isEmpty }) {
                genreCounts[name, default: 0] += 1
            }
        }
        var topGenres: [LifetimeRanking] = genreCounts.map { entry in
            LifetimeRanking(name: entry.key, count: entry.value)
        }
        topGenres.sort(by: rankingOrder)

        var decadeCounts: [Int: Int] = [:]
        for year in (movies.map(\.releaseYear) + watchedShows.map(\.firstAirYear)).compactMap({ $0 }) where year > 0 {
            decadeCounts[(year / 10) * 10, default: 0] += 1
        }
        var topDecades: [LifetimeRanking] = decadeCounts.map { entry in
            LifetimeRanking(name: String(entry.key) + "s", count: entry.value)
        }
        topDecades.sort(by: rankingOrder)

        let episodeCounts: [Int: Int] = Dictionary(grouping: episodes, by: \.showID).mapValues { $0.count }
        let episodeNames = Dictionary(grouping: episodes, by: \.showID).compactMapValues { records in
            records.first(where: { !$0.showName.isEmpty })?.showName
        }
        var topShows: [LifetimeShowRanking] = episodeCounts.map { entry in
            let fallbackName = episodeNames[entry.key] ?? ""
            let name = showsByID[entry.key]?.name ?? fallbackName
            return LifetimeShowRanking(showID: entry.key, name: name, episodeCount: entry.value)
        }
        topShows.sort {
            if $0.episodeCount != $1.episodeCount { return $0.episodeCount > $1.episodeCount }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }

        let favorites = movies.compactMap { movie -> LifetimeFavoriteMovie? in
            guard let rating = movie.personalRating, rating > 0 else { return nil }
            return LifetimeFavoriteMovie(id: movie.id, title: movie.title, rating: rating)
        }.sorted { $0.rating == $1.rating ? $0.title.localizedStandardCompare($1.title) == .orderedAscending : $0.rating > $1.rating }

        let totalMinutes = minutes.reduce(0, +)
        var milestones: [LifetimeMilestone] = []
        if !movies.isEmpty { milestones.append(.firstMovie) }
        if movies.count >= 10 { milestones.append(.tenMovies) }
        if movies.count >= 100 { milestones.append(.hundredMovies) }
        if !episodes.isEmpty { milestones.append(.firstEpisode) }
        if episodes.count >= 100 { milestones.append(.hundredEpisodes) }
        if episodes.count >= 1_000 { milestones.append(.thousandEpisodes) }
        if totalMinutes >= 6_000 { milestones.append(.hundredHours) }
        if totalMinutes >= 43_200 { milestones.append(.thirtyDays) }

        return LifetimeSnapshot(
            movieCount: movies.count,
            episodeCount: episodes.count,
            totalKnownMinutes: totalMinutes,
            knownDurationCount: minutes.count,
            undatedItemCount: dates.count - dated.count,
            monthlyTimeline: timeline,
            topGenres: topGenres,
            topDecades: topDecades,
            topShows: topShows,
            favoriteMovies: favorites,
            milestones: milestones
        )
    }

    /// A descriptive comparison, not a measurement of actual playback time.
    public static func lifePercentage(totalKnownMinutes: Int, birthDate: Date?, now: Date = .now) -> Double? {
        guard let birthDate, birthDate < now, totalKnownMinutes >= 0 else { return nil }
        let livedMinutes = now.timeIntervalSince(birthDate) / 60
        guard livedMinutes > 0 else { return nil }
        return Double(totalKnownMinutes) / livedMinutes * 100
    }

    private static func rankingOrder(_ lhs: LifetimeRanking, _ rhs: LifetimeRanking) -> Bool {
        if lhs.count != rhs.count { return lhs.count > rhs.count }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    private static func mergeMovies(_ duplicates: [LifetimeMovieRecord]) -> LifetimeMovieRecord? {
        guard let first = duplicates.first else { return nil }
        return LifetimeMovieRecord(
            id: first.id,
            title: duplicates.first(where: { !$0.title.isEmpty })?.title ?? first.title,
            watchedAt: duplicates.compactMap(\.watchedAt).min(),
            runtimeMinutes: duplicates.compactMap(\.runtimeMinutes).first(where: { $0 > 0 }),
            genres: duplicates.first(where: { !$0.genres.isEmpty })?.genres ?? [],
            releaseYear: duplicates.compactMap(\.releaseYear).first,
            personalRating: duplicates.compactMap(\.personalRating).first
        )
    }

    private static func mergeEpisodes(_ duplicates: [LifetimeEpisodeRecord]) -> LifetimeEpisodeRecord? {
        guard let first = duplicates.first else { return nil }
        return LifetimeEpisodeRecord(
            showID: first.showID,
            showName: duplicates.first(where: { !$0.showName.isEmpty })?.showName ?? first.showName,
            seasonNumber: first.seasonNumber,
            episodeNumber: first.episodeNumber,
            watchedAt: duplicates.compactMap(\.watchedAt).min(),
            runtimeMinutes: duplicates.compactMap(\.runtimeMinutes).first(where: { $0 > 0 })
        )
    }
}
