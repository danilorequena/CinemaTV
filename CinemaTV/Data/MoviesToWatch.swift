//
//  MoviesToWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 16/07/23.
//
//

import Foundation
import SwiftData


@Model public class MoviesToWatch {
    public var id: Int64?
    var counter: Double?
    var name: String?
    var overview: String?
    var profilePath: String?
    
    init(
        id: Int64? = nil,
        counter: Double? = nil,
        name: String? = nil,
        overview: String? = nil,
        profilePath: String? = nil
    ) {
        self.id = id
        self.counter = counter
        self.name = name
        self.overview = overview
        self.profilePath = profilePath
    }
}
