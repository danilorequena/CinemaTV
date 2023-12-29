//
//  TVShowSDModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/11/23.
//

import SwiftData

@Model final class TVShowWatchingModel {
    var id: Int? = nil
    var name: String?
    var overview: String?
    var imagePath: String?
    @Relationship(deleteRule: .cascade, inverse: \SeasonSD.tvShow) var seasons: [SeasonSD]?
    
    init(
        id: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        imagePath: String? = nil,
        seasons: [SeasonSD]? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.imagePath = imagePath
        self.seasons = seasons
    }
}
