//
//  TVShowModels.swift
//  CinemaTVKit
//
//  Estrutura de dados de TV Shows (V2). Mesmos nomes das classes legadas.
//

import Foundation
import SwiftData

@Model
public final class TVShowWatchingModel {
    public var id: Int?
    public var name: String?
    public var overview: String?
    public var imagePath: String?
    public var voteAverage: Double?
    public var firstAirDate: String?
    /// Soma dos episodeCount das temporadas regulares (denominador do
    /// progresso da série; reconciliado em refreshMetadata).
    public var totalEpisodes: Int?
    public var dateAdded: Date?
    public var sortIndex: Int?
    // Cache denormalizado do próximo episódio não assistido. Mora no show
    // (e não é computado on-the-fly) para a @Query da tab Tracking observar
    // o objeto certo quando um EpisodeSD muda.
    public var nextEpisodeSeason: Int?
    public var nextEpisodeNumber: Int?
    public var nextEpisodeName: String?
    public var nextEpisodeStillPath: String?
    /// Cache denormalizado do último episódio marcado (max watchedAt) —
    /// ordena a Library por "continue de onde parou" sem varrer relações.
    public var lastActivityAt: Date?
    // Cache do next_episode_to_air do TMDB (episódio AINDA NÃO exibido) —
    // alimenta a agenda "Up Next" de estreias. episodeNumber == 1 significa
    // estreia de temporada. Atualizado em follow/refreshMetadata.
    public var upcomingAirDate: String?
    public var upcomingSeason: Int?
    public var upcomingEpisode: Int?
    public var upcomingEpisodeName: String?
    /// Status TMDB ("Ended"/"Canceled"/"Returning Series") — decide se uma
    /// série completada pode voltar ao Watching quando vierem episódios.
    public var status: String?
    @Relationship(deleteRule: .cascade, inverse: \SeasonSD.tvShow)
    public var seasons: [SeasonSD]?

    public init(
        id: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        imagePath: String? = nil,
        voteAverage: Double? = nil,
        firstAirDate: String? = nil,
        totalEpisodes: Int? = nil,
        dateAdded: Date? = nil,
        sortIndex: Int? = nil,
        seasons: [SeasonSD]? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.imagePath = imagePath
        self.voteAverage = voteAverage
        self.firstAirDate = firstAirDate
        self.totalEpisodes = totalEpisodes
        self.dateAdded = dateAdded
        self.sortIndex = sortIndex
        self.seasons = seasons
    }
}

// Todo-opcional (diferente do legado): a classe nunca entrou no container,
// então não há dados a preservar, e o shape antigo violava as regras do CloudKit.
@Model
public final class TVShowWatchedModel {
    public var id: Int?
    public var name: String?
    public var overview: String?
    public var imagePath: String?

    public init(
        id: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        imagePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.imagePath = imagePath
    }
}

@Model
public final class SeasonSD {
    public var id: Int?
    public var airDate: String?
    public var episodeCount: Int?
    public var name: String?
    public var overview: String?
    public var posterPath: String?
    public var seasonNumber: Int?
    public var tvShow: TVShowWatchingModel?
    @Relationship(deleteRule: .cascade, inverse: \EpisodeSD.season)
    public var episodes: [EpisodeSD]?

    public init(
        id: Int? = nil,
        airDate: String? = nil,
        episodeCount: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        seasonNumber: Int? = nil,
        tvShow: TVShowWatchingModel? = nil,
        episodes: [EpisodeSD]? = nil
    ) {
        self.id = id
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.seasonNumber = seasonNumber
        self.tvShow = tvShow
        self.episodes = episodes
    }
}

@Model
public final class EpisodeSD {
    public var id: Int?
    public var airDate: String?
    public var episodeNumber: Int?
    public var name: String?
    public var overview: String?
    public var productionCode: String?
    public var runtime: Int?
    public var seasonNumber: Int?
    public var showID: Int?
    public var stillPath: String?
    public var voteAverage: Double?
    public var voteCount: Int?
    /// A existência do record já significa "assistido" (modelo esparso);
    /// a data serve para ordenação e estatísticas.
    public var watchedAt: Date?
    public var season: SeasonSD?

    public init(
        id: Int? = nil,
        airDate: String? = nil,
        episodeNumber: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        productionCode: String? = nil,
        runtime: Int? = nil,
        seasonNumber: Int? = nil,
        showID: Int? = nil,
        stillPath: String? = nil,
        voteAverage: Double? = nil,
        voteCount: Int? = nil,
        watchedAt: Date? = nil,
        season: SeasonSD? = nil
    ) {
        self.id = id
        self.airDate = airDate
        self.episodeNumber = episodeNumber
        self.name = name
        self.overview = overview
        self.productionCode = productionCode
        self.runtime = runtime
        self.seasonNumber = seasonNumber
        self.showID = showID
        self.stillPath = stillPath
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.watchedAt = watchedAt
        self.season = season
    }
}
