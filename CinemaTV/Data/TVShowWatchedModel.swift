//
//  TVShowWatchedModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/11/23.
//

import SwiftData

@Model public class TVShowWatchedModel {
    public var id: Int
    var name: String
    var overview: String
    var imagePath: String?
    var episodes: [Episode]
    
    init(id: Int, name: String, overview: String, imagePath: String? = nil, episodes: [Episode]) {
        self.id = id
        self.name = name
        self.overview = overview
        self.imagePath = imagePath
        self.episodes = episodes
    }
}

