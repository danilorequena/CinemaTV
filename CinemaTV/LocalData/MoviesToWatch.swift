//
//  MoviesToWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 16/06/23.
//
//

import Foundation
import SwiftData


@Model final public class MoviesToWatch {
    public var id: Int64? = 0
    var name: String?
    var overview: String?
    var profilePath: String?
    
    init(id: Int64? = nil, name: String? = nil, overview: String? = nil, profilePath: String? = nil) {
        self.id = id
        self.name = name
        self.overview = overview
        self.profilePath = profilePath
    }
}
