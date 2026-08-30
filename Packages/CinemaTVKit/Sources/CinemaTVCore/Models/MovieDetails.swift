//
//  MovieDetails.swift
//  CinemaTVKit
//

import Foundation

public struct MovieDetails: Identifiable, Hashable, Sendable, Decodable {
    public struct Genre: Identifiable, Hashable, Sendable, Decodable {
        public let id: Int
        public let name: String
    }

    public let id: Int
    public let title: String
    /// Título original (TMDB `original_title`) — útil para buscas em
    /// catálogos externos quando o título exibido está localizado.
    public let originalTitle: String?
    public let overview: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let runtime: Int?
    public let voteAverage: Double?
    public let voteCount: Int?
    public let tagline: String?
    public let genres: [Genre]?
    public let status: String?

    public var posterURL: URL? { TMDBImage.url(path: posterPath, size: .poster) }
    public var backdropURL: URL? { TMDBImage.url(path: backdropPath, size: .backdrop) }

    /// Ano de lançamento ("yyyy-MM-dd" → Int), quando conhecido.
    public var releaseYear: Int? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        return Int(releaseDate.prefix(4))
    }

    public var formattedRuntime: String? {
        guard let runtime, runtime > 0 else { return nil }
        return Duration.seconds(runtime * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    public var mediaItem: MediaItem {
        MediaItem(
            id: id,
            title: title,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage ?? 0,
            releaseDate: releaseDate,
            mediaType: .movie
        )
    }
}
