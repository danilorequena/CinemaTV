import Foundation

public struct TraktIDs: Codable, Sendable, Equatable {
    public let trakt: Int
    public let slug: String?
    public let imdb: String?
    public let tmdb: Int?
}

public struct TraktMovie: Codable, Sendable, Equatable {
    public let title: String
    public let year: Int?
    public let ids: TraktIDs
}

public struct TraktShow: Codable, Sendable, Equatable {
    public let title: String
    public let year: Int?
    public let ids: TraktIDs
}

public struct TraktWatchlistItem: Codable, Sendable, Equatable {
    public let listedAt: Date
    public let movie: TraktMovie?
    public let show: TraktShow?

    public var canonicalTMDBID: Int? {
        movie?.ids.tmdb ?? show?.ids.tmdb
    }

    enum CodingKeys: String, CodingKey {
        case listedAt = "listed_at"
        case movie
        case show
    }
}

public struct TraktWatchedMovie: Codable, Sendable, Equatable {
    public let plays: Int?
    public let lastWatchedAt: Date?
    public let lastUpdatedAt: Date?
    public let movie: TraktMovie

    enum CodingKeys: String, CodingKey {
        case plays
        case lastWatchedAt = "last_watched_at"
        case lastUpdatedAt = "last_updated_at"
        case movie
    }
}

public struct TraktWatchedShow: Codable, Sendable, Equatable {
    public let plays: Int?
    public let lastWatchedAt: Date?
    public let lastUpdatedAt: Date?
    public let show: TraktShow
    public let seasons: [TraktWatchedSeason]?

    enum CodingKeys: String, CodingKey {
        case plays
        case lastWatchedAt = "last_watched_at"
        case lastUpdatedAt = "last_updated_at"
        case show
        case seasons
    }
}

public struct TraktWatchedSeason: Codable, Sendable, Equatable {
    public let number: Int
    public let episodes: [TraktWatchedEpisode]
}

public struct TraktWatchedEpisode: Codable, Sendable, Equatable {
    public let number: Int
    public let plays: Int?
    public let lastWatchedAt: Date?
    public let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case number
        case plays
        case lastWatchedAt = "last_watched_at"
        case completedAt = "completed_at"
    }
}

public struct TraktUserSettings: Codable, Sendable, Equatable {
    public struct User: Codable, Sendable, Equatable {
        public let username: String?
        public let name: String?
        public let ids: UserIDs?
    }

    public struct UserIDs: Codable, Sendable, Equatable {
        public let slug: String?
        public let uuid: String?
    }

    public let user: User
}

public extension JSONDecoder {
    static var trakt: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) {
                return date
            }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Invalid Trakt ISO-8601 date: \(value)"
            )
        }
        return decoder
    }
}
