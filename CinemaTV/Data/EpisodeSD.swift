//
//  EpisodeSD.swift
//  CinemaTV
//
//  Created by Danilo Requena on 12/31/23.
//

import SwiftData

@Model
final class EpisodeSD {
    var id: Int?
    var airDate: String?
    var episodeNumber: Int?
    var name: String?
    var overview: String?
    var productionCode: String?
    var runtime: Int?
    var seasonNumber: Int?
    var showID: Int?
    var stillPath: String?
    var voteAverage: Double?
    var voteCount: Int?
    var season: SeasonSD?
    
    init(
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
        season: SeasonSD? = nil
    ){
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
        self.season = season
    }
}
