//
//  SeasonSD.swift
//  CinemaTV
//
//  Created by Danilo Requena on 12/29/23.
//

import SwiftData
import Foundation

@Model class SeasonSD {
    var id: Int?
    var airDate: String?
    var episodeCount: Int?
    var name: String?
    var overview: String?
    var posterPath: String?
    var seasonNumber: Int?
    var tvShow: TVShowWatchingModel?
    
    init(
        id: Int? = nil,
        airDate: String? = nil,
        episodeCount: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        seasonNumber: Int? = nil,
        tvShow: TVShowWatchingModel? = nil
    ) {
        self.id = id
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.seasonNumber = seasonNumber
        self.tvShow = tvShow
    }
}
