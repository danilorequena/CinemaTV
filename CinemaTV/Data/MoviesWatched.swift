//
//  MoviesWatched.swift
//  CinemaTV
//
//  Created by Danilo Requena on 16/07/23.
//
//

import Foundation
import SwiftData


@Model public class MoviesWatched {
    var counter: Double? = 0.0
    public var id: Int64? = 0
    var name: String?
    var overview: String?
    var profilePath: String?
    
    init(counter: Double? = nil, id: Int64? = nil, name: String? = nil, overview: String? = nil, profilePath: String? = nil) {
        self.counter = counter
        self.id = id
        self.name = name
        self.overview = overview
        self.profilePath = profilePath
    }
}
