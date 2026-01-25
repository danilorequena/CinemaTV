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
    @Relationship(deleteRule: .cascade, inverse: \EpisodeSD.season)
    var episodes: [EpisodeSD]?

    var watchedEpisodesCount: Int {
        episodes?.filter { $0.isWatched }.count ?? 0
    }

    var progressPercentage: Double? {
        guard let total = episodeCount, total > 0 else { return nil }
        return Double(watchedEpisodesCount) / Double(total)
    }

    init(
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
