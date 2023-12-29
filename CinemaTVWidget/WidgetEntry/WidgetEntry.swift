//
//  WidgetEntry.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/04/23.
//

import WidgetKit

struct WidgetEntry: TimelineEntry, Decodable {
    var date: Date
    var widgetData: [MovieResultModel]
}

struct MovieModel: Codable {
    let results: [MovieResultModel]
}

struct MovieResultModel: Codable, Hashable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let poster_path: String
}
