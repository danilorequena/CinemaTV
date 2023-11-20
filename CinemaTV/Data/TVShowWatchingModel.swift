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
    var episodes: [EpisodeSD]
    
    init(id: Int, name: String, overview: String, imagePath: String? = nil, episodes: [EpisodeSD]) {
        self.id = id
        self.name = name
        self.overview = overview
        self.imagePath = imagePath
        self.episodes = episodes
    }
}

@Model public class EpisodeSD {
    public var id: Int
    var airDate: String?
    var episodeNumber: Int?
    var name: String?
    var overview: String?
    var productionCode: String?
    var seasonNumber: Int?
    var showID: Int?
    var stillPath: String?
    var voteAverage: Double?
    var voteCount: Int?
    var runtime: Int?
    
    init(id: Int, airDate: String? = nil, episodeNumber: Int? = nil, name: String? = nil, overview: String? = nil, productionCode: String? = nil, seasonNumber: Int? = nil, showID: Int? = nil, stillPath: String? = nil, voteAverage: Double? = nil, voteCount: Int? = nil, runtime: Int? = nil) {
        self.airDate = airDate
        self.episodeNumber = episodeNumber
        self.id = id
        self.name = name
        self.overview = overview
        self.productionCode = productionCode
        self.seasonNumber = seasonNumber
        self.showID = showID
        self.stillPath = stillPath
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.runtime = runtime
    }
}
