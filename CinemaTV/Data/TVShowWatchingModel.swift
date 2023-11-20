//
//  TVShowSDModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/11/23.
//

import SwiftData

@Model public class TVShowWatchingModel {
    public var id: Int
    var name: String
    var overview: String
    var imagePath: String?
    var seasons: [SeasonSD]
    
    init(
        id: Int,
        name: String,
        overview: String,
        imagePath: String? = nil,
        seasons: [SeasonSD]
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.imagePath = imagePath
        self.seasons = seasons
    }
}

@Model public class SeasonSD {
    public var id: Int
    var airDate: String?
    var episodeCount: Int?
    var name: String?
    var overview: String?
    var posterPath: String?
    var seasonNumber: Int?
    var episodes: [EpisodeSD]
    
    init(
        id: Int,
        airDate: String? = nil,
        episodeCount: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        seasonNumber: Int? = nil,
        episodes: [EpisodeSD]
    ) {
        self.id = id
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.seasonNumber = seasonNumber
        self.episodes = episodes
    }
}

@Model public class EpisodeSD {
    public var id: Int
    var airDate: String?
    var episodeNumber: Int?
    var name: String
    var overview: String?
    var productionCode: String?
    var runtime: Int?
    var seasonNumber: Int?
    public var showID: Int
    var stillPath: String?
    var voteAverage: Double?
    var voteCount: Int?
    
    init(
        id: Int,
        airDate: String? = nil,
        episodeNumber: Int? = nil,
        name: String,
        overview: String? = nil,
        productionCode: String? = nil,
        runtime: Int? = nil,
        seasonNumber: Int? = nil,
        showID: Int,
        stillPath: String? = nil,
        voteAverage: Double? = nil,
        voteCount: Int? = nil
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
    }
}

