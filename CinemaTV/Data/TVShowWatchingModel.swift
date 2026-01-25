//
//  TVShowSDModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/11/23.
//

import Foundation
import SwiftData

@Model final class TVShowWatchingModel {
    var id: Int? = nil
    var name: String?
    var overview: String?
    var imagePath: String?
    var lastUpdated: Date = Date()
    var currentSeasonNumber: Int?
    var currentEpisodeNumber: Int?
    @Relationship(deleteRule: .cascade, inverse: \SeasonSD.tvShow) var seasons: [SeasonSD]?

    var currentSeasonProgress: Double? {
        guard let currentSeason = currentSeasonNumber,
              let seasons = seasons,
              let season = seasons.first(where: { $0.seasonNumber == currentSeason })
        else { return nil }
        return season.progressPercentage
    }

    init(
        id: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        imagePath: String? = nil,
        lastUpdated: Date = Date(),
        currentSeasonNumber: Int? = nil,
        currentEpisodeNumber: Int? = nil,
        seasons: [SeasonSD]? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.imagePath = imagePath
        self.lastUpdated = lastUpdated
        self.currentSeasonNumber = currentSeasonNumber
        self.currentEpisodeNumber = currentEpisodeNumber
        self.seasons = seasons
    }
}
