import Foundation

public struct LifetimeMovieMetadata: Codable, Sendable, Equatable {
    public let runtimeMinutes: Int?
    public let genres: [String]
    public let releaseYear: Int?

    public init(runtimeMinutes: Int?, genres: [String], releaseYear: Int?) {
        self.runtimeMinutes = runtimeMinutes
        self.genres = genres
        self.releaseYear = releaseYear
    }
}

public struct LifetimeShowMetadata: Codable, Sendable, Equatable {
    public let genres: [String]
    public let firstAirYear: Int?

    public init(genres: [String], firstAirYear: Int?) {
        self.genres = genres
        self.firstAirYear = firstAirYear
    }
}

public struct LifetimeSeasonMetadata: Codable, Sendable, Equatable {
    public let runtimesByEpisode: [Int: Int]

    public init(runtimesByEpisode: [Int: Int]) {
        self.runtimesByEpisode = runtimesByEpisode
    }
}

/// TMDB detail data is public catalogue metadata, kept on this device only.
/// Personal tracking and the optional birth date remain in the SwiftData store.
public actor LifetimeMetadataCache {
    private struct Storage: Codable {
        var movies: [String: LifetimeMovieMetadata] = [:]
        var shows: [String: LifetimeShowMetadata] = [:]
        var seasons: [String: LifetimeSeasonMetadata] = [:]

        private enum CodingKeys: String, CodingKey { case movies, shows, seasons }

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            movies = try container.decodeIfPresent([String: LifetimeMovieMetadata].self, forKey: .movies) ?? [:]
            shows = try container.decodeIfPresent([String: LifetimeShowMetadata].self, forKey: .shows) ?? [:]
            seasons = try container.decodeIfPresent([String: LifetimeSeasonMetadata].self, forKey: .seasons) ?? [:]
        }
    }

    private let fileURL: URL
    private var storage: Storage
    private var isDirty = false
    private var pendingWrite: Task<Void, Never>?

    public init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(Storage.self, from: data) {
            storage = decoded
        } else {
            storage = Storage()
        }
    }

    public func movie(id: Int, locale: String) -> LifetimeMovieMetadata? {
        storage.movies[Self.key(id: id, locale: locale)]
    }

    public func show(id: Int, locale: String) -> LifetimeShowMetadata? {
        storage.shows[Self.key(id: id, locale: locale)]
    }

    public func season(showID: Int, seasonNumber: Int, locale: String) -> LifetimeSeasonMetadata? {
        storage.seasons[Self.seasonKey(showID: showID, seasonNumber: seasonNumber, locale: locale)]
    }

    public func cachedMovies(ids: [Int], locale: String) -> [Int: LifetimeMovieMetadata] {
        var result: [Int: LifetimeMovieMetadata] = [:]
        for id in ids { result[id] = movie(id: id, locale: locale) }
        return result
    }

    public func cachedShows(ids: [Int], locale: String) -> [Int: LifetimeShowMetadata] {
        var result: [Int: LifetimeShowMetadata] = [:]
        for id in ids { result[id] = show(id: id, locale: locale) }
        return result
    }

    public func cachedSeasons(keys: [LifetimeSeasonKey], locale: String) -> [LifetimeSeasonKey: LifetimeSeasonMetadata] {
        var result: [LifetimeSeasonKey: LifetimeSeasonMetadata] = [:]
        for key in keys { result[key] = season(showID: key.showID, seasonNumber: key.seasonNumber, locale: locale) }
        return result
    }

    public func putMovie(_ metadata: LifetimeMovieMetadata, id: Int, locale: String) {
        storage.movies[Self.key(id: id, locale: locale)] = metadata
        schedulePersist()
    }

    public func putShow(_ metadata: LifetimeShowMetadata, id: Int, locale: String) {
        storage.shows[Self.key(id: id, locale: locale)] = metadata
        schedulePersist()
    }

    public func putSeason(_ metadata: LifetimeSeasonMetadata, showID: Int, seasonNumber: Int, locale: String) {
        storage.seasons[Self.seasonKey(showID: showID, seasonNumber: seasonNumber, locale: locale)] = metadata
        schedulePersist()
    }

    /// Coalesces frequent TMDB responses into one local disk write.
    public func flush() {
        pendingWrite?.cancel()
        pendingWrite = nil
        guard isDirty else { return }
        persist()
    }

    public func loadMovie(id: Int, locale: String, client: TMDBClient) async throws -> LifetimeMovieMetadata {
        if let cached = movie(id: id, locale: locale) { return cached }
        let details: MovieDetails = try await client.fetch(.movieDetail(id: id))
        try Task.checkCancellation()
        let metadata = LifetimeMovieMetadata(runtimeMinutes: details.runtime, genres: details.genres?.map(\.name) ?? [], releaseYear: details.releaseYear)
        putMovie(metadata, id: id, locale: locale)
        return metadata
    }

    public func loadShow(id: Int, locale: String, client: TMDBClient) async throws -> LifetimeShowMetadata {
        if let cached = show(id: id, locale: locale) { return cached }
        let details: TVShowDetails = try await client.fetch(.tvShowDetail(id: id))
        try Task.checkCancellation()
        let metadata = LifetimeShowMetadata(genres: details.genres?.map(\.name) ?? [], firstAirYear: details.firstAirYear)
        putShow(metadata, id: id, locale: locale)
        return metadata
    }

    public func loadSeason(showID: Int, seasonNumber: Int, locale: String, client: TMDBClient) async throws -> LifetimeSeasonMetadata {
        if let cached = season(showID: showID, seasonNumber: seasonNumber, locale: locale) { return cached }
        let details: SeasonDetails = try await client.fetch(.tvShowSeason(id: showID, season: seasonNumber))
        try Task.checkCancellation()
        let runtimes = Dictionary(uniqueKeysWithValues: details.episodes.compactMap { episode -> (Int, Int)? in
            guard let runtime = episode.runtime, runtime > 0 else { return nil }
            return (episode.episodeNumber, runtime)
        })
        let metadata = LifetimeSeasonMetadata(runtimesByEpisode: runtimes)
        putSeason(metadata, showID: showID, seasonNumber: seasonNumber, locale: locale)
        return metadata
    }

    private func persist() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(storage).write(to: fileURL, options: .atomic)
            isDirty = false
        } catch {
            // Data remains available in memory; a later successful write can
            // restore offline reuse without affecting personal statistics.
        }
    }

    private func schedulePersist() {
        isDirty = true
        guard pendingWrite == nil else { return }
        pendingWrite = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            await self?.flush()
        }
    }

    private static func key(id: Int, locale: String) -> String { "\(locale):\(id)" }
    private static func seasonKey(showID: Int, seasonNumber: Int, locale: String) -> String {
        "\(locale):\(showID):\(seasonNumber)"
    }
}

public struct LifetimeSeasonKey: Hashable, Sendable, Codable, Comparable {
    public let showID: Int
    public let seasonNumber: Int

    public init(showID: Int, seasonNumber: Int) {
        self.showID = showID
        self.seasonNumber = seasonNumber
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.showID, lhs.seasonNumber) < (rhs.showID, rhs.seasonNumber)
    }
}
