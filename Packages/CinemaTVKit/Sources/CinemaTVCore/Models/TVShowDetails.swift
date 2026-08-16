//
//  TVShowDetails.swift
//  CinemaTVKit
//
//  Estrutura pronta para a V2 (TV Shows). Nenhuma tela V1 consome isso,
//  mas rotas, entidades e o TMDBClient já contemplam o tipo.
//

import Foundation

public struct TVShowDetails: Identifiable, Hashable, Sendable, Decodable {
    /// Criador(es) da série (created_by).
    public struct Creator: Identifiable, Hashable, Sendable, Decodable {
        public let id: Int
        public let name: String
    }

    /// Emissora/plataforma original (networks).
    public struct Network: Identifiable, Hashable, Sendable, Decodable {
        public let id: Int
        public let name: String
        public let logoPath: String?
    }

    public let id: Int
    public let name: String
    public let overview: String?
    public let tagline: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let firstAirDate: String?
    public let numberOfSeasons: Int?
    public let numberOfEpisodes: Int?
    public let voteAverage: Double?
    public let voteCount: Int?
    public let genres: [MovieDetails.Genre]?
    public let status: String?
    public let createdBy: [Creator]?
    public let networks: [Network]?
    /// O shape do next_episode_to_air do TMDB casa com EpisodeSummary.
    public let nextEpisodeToAir: EpisodeSummary?
    public let seasons: [SeasonSummary]?

    public init(
        id: Int,
        name: String,
        overview: String? = nil,
        tagline: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        firstAirDate: String? = nil,
        numberOfSeasons: Int? = nil,
        numberOfEpisodes: Int? = nil,
        voteAverage: Double? = nil,
        voteCount: Int? = nil,
        genres: [MovieDetails.Genre]? = nil,
        status: String? = nil,
        createdBy: [Creator]? = nil,
        networks: [Network]? = nil,
        nextEpisodeToAir: EpisodeSummary? = nil,
        seasons: [SeasonSummary]? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.tagline = tagline
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.firstAirDate = firstAirDate
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.genres = genres
        self.status = status
        self.createdBy = createdBy
        self.networks = networks
        self.nextEpisodeToAir = nextEpisodeToAir
        self.seasons = seasons
    }

    public var posterURL: URL? { TMDBImage.url(path: posterPath, size: .poster) }
    public var backdropURL: URL? { TMDBImage.url(path: backdropPath, size: .backdrop) }

    public var mediaItem: MediaItem {
        MediaItem(
            id: id,
            title: name,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage ?? 0,
            releaseDate: firstAirDate,
            mediaType: .tvShow
        )
    }
}

public struct SeasonSummary: Identifiable, Hashable, Sendable, Decodable {
    public let id: Int
    public let name: String
    public let overview: String?
    public let posterPath: String?
    public let seasonNumber: Int
    public let episodeCount: Int?
    public let airDate: String?

    public init(
        id: Int,
        name: String,
        overview: String? = nil,
        posterPath: String? = nil,
        seasonNumber: Int,
        episodeCount: Int? = nil,
        airDate: String? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.seasonNumber = seasonNumber
        self.episodeCount = episodeCount
        self.airDate = airDate
    }

    public var posterURL: URL? { TMDBImage.url(path: posterPath, size: .poster) }
}

public struct SeasonDetails: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let name: String
    public let overview: String?
    public let posterPath: String?
    public let airDate: String?
    public let seasonNumber: Int
    public let episodes: [EpisodeSummary]

    public init(
        id: String,
        name: String,
        overview: String? = nil,
        posterPath: String? = nil,
        airDate: String? = nil,
        seasonNumber: Int,
        episodes: [EpisodeSummary]
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.airDate = airDate
        self.seasonNumber = seasonNumber
        self.episodes = episodes
    }

    public var posterURL: URL? { TMDBImage.url(path: posterPath, size: .poster) }

    public var airYear: String? {
        guard let airDate, airDate.count >= 4 else { return nil }
        return String(airDate.prefix(4))
    }

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, overview, posterPath, airDate, seasonNumber, episodes
    }
}

public struct EpisodeSummary: Identifiable, Hashable, Sendable, Decodable {
    public let id: Int
    public let name: String
    public let overview: String?
    public let episodeNumber: Int
    public let seasonNumber: Int?
    public let airDate: String?
    public let runtime: Int?
    public let stillPath: String?
    public let voteAverage: Double?
    // O payload de /tv/{id}/season/{n} traz elenco convidado e equipe por
    // episódio — é a fonte do detalhe de episódio, sem endpoint próprio.
    public let guestStars: [CastMember]?
    public let crew: [CrewMember]?

    public init(
        id: Int,
        name: String,
        overview: String? = nil,
        episodeNumber: Int,
        seasonNumber: Int? = nil,
        airDate: String? = nil,
        runtime: Int? = nil,
        stillPath: String? = nil,
        voteAverage: Double? = nil,
        guestStars: [CastMember]? = nil,
        crew: [CrewMember]? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.airDate = airDate
        self.runtime = runtime
        self.stillPath = stillPath
        self.voteAverage = voteAverage
        self.guestStars = guestStars
        self.crew = crew
    }

    public var stillURL: URL? { TMDBImage.url(path: stillPath, size: .backdrop) }

    public var formattedRuntime: String? {
        guard let runtime, runtime > 0 else { return nil }
        return Duration.seconds(runtime * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }
}
