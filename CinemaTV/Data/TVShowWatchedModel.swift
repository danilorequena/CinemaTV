//
//  TVShowWatchedModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/11/23.
//

import SwiftData
import Foundation

@Model
final class TVShowWatchedModel {
    @Attribute var id: UUID
    var title: String
    var overview: String
    var releaseDate: Date
    var imagePath: String
    @Relationship var seasons: [SeasonDataModel]
    
    init(id: UUID = UUID(), title: String, overview: String, releaseDate: Date, imagePath: String) {
        self.id = id
        self.title = title
        self.overview = overview
        self.releaseDate = releaseDate
        self.imagePath = imagePath
        self.seasons = []
    }
}

@Model
public class SeasonDataModel {
    @Attribute public var id: Int?
    var seasonNumber: Int?
    var releaseDate: Date?
    @Relationship(inverse: \TVShowDataModel.seasons) var tvShow: TVShowDataModel?
    @Relationship var episodes: [EpisodeDataModel]?
    
    init(
        id: Int? = nil,
        seasonNumber: Int? = nil,
        releaseDate: Date? = nil,
        tvShow: TVShowDataModel? = nil
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.releaseDate = releaseDate
        self.tvShow = tvShow
        self.episodes = []
    }
}

@Model
public class EpisodeDataModel {
    @Attribute public var id: Int?
    var title: String?
    var duration: Int?
    var releaseDate: String?
    @Relationship(inverse: \SeasonDataModel.episodes) var season: SeasonDataModel?
    
    init(id: Int? = nil, title: String? = nil, duration: Int? = nil, releaseDate: String? = nil, season: SeasonDataModel? = nil) {
        self.id = id
        self.title = title
        self.duration = duration
        self.releaseDate = releaseDate
        self.season = season
    }
}
