//
//  TVShowDataModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 6/1/24.
//

//
//  TVShowWatchedModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/11/23.
//

import SwiftData
import Foundation

@Model
public class TVShowDataModel {
    @Attribute public var id: Int?
    var title: String?
    var overview: String?
    var releaseDate: Date?
    var imagePath: String?
    @Relationship var seasons: [SeasonDataModel]?
    
    init(
        id: Int? = nil,
        title: String? = nil,
        overview: String? = nil,
        releaseDate: Date? = nil,
        imagePath: String? = nil,
        seasons: [SeasonDataModel]? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.releaseDate = releaseDate
        self.imagePath = imagePath
        self.seasons = seasons
    }
}
