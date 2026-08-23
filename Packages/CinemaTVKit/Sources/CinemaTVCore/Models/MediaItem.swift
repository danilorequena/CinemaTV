//
//  MediaItem.swift
//  CinemaTVKit
//
//  Modelo leve de exibição: é o que MediaCard/MediaCarousel renderizam e o
//  que o MovieEntity (App Intents) embrulha. Decodifica tanto payloads de
//  filmes (title/release_date) quanto de séries (name/first_air_date).
//

import Foundation

public struct MediaItem: Identifiable, Hashable, Sendable {
    public enum MediaType: String, Sendable, Codable {
        case movie
        case tvShow = "tv"
        case person
    }

    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Double
    public let releaseDate: String?
    public let mediaType: MediaType
    /// Papel numa filmografia (combined_credits); nil fora desse contexto.
    public let character: String?
    /// IDs de gênero do TMDB (genre_ids das listas); nil quando o payload
    /// não traz (detalhes usam `genres` expandido).
    public let genreIds: [Int]?

    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        voteAverage: Double,
        releaseDate: String?,
        mediaType: MediaType,
        character: String? = nil,
        genreIds: [Int]? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.releaseDate = releaseDate
        self.mediaType = mediaType
        self.character = character
        self.genreIds = genreIds
    }

    public var releaseYear: String? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        return String(releaseDate.prefix(4))
    }

    public var posterURL: URL? { TMDBImage.url(path: posterPath, size: .poster) }
    public var backdropURL: URL? { TMDBImage.url(path: backdropPath, size: .backdrop) }
}

extension MediaItem: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath, backdropPath, profilePath
        case voteAverage
        case releaseDate, firstAirDate
        case mediaType
        case character
        case genreIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0

        let movieTitle = try container.decodeIfPresent(String.self, forKey: .title)
        let tvName = try container.decodeIfPresent(String.self, forKey: .name)
        title = movieTitle ?? tvName ?? ""

        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            ?? container.decodeIfPresent(String.self, forKey: .firstAirDate)

        // multi-search traz media_type; endpoints tipados (discover/movie etc.) não.
        if let explicit = try container.decodeIfPresent(MediaType.self, forKey: .mediaType) {
            mediaType = explicit
        } else {
            mediaType = movieTitle != nil ? .movie : .tvShow
        }

        // Pessoas em multi-search usam profile_path como imagem.
        let poster = try container.decodeIfPresent(String.self, forKey: .posterPath)
        let profile = try container.decodeIfPresent(String.self, forKey: .profilePath)
        posterPath = poster ?? profile

        character = try container.decodeIfPresent(String.self, forKey: .character)
        genreIds = try container.decodeIfPresent([Int].self, forKey: .genreIds)
    }
}
