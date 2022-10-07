//
//  DiscoverTVShow.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/09/22.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let discoverTVShow = try? newJSONDecoder().decode(DiscoverTVShow.self, from: jsonData)

import Foundation

// MARK: - DiscoverTVShow
struct DiscoverTVShow: Codable {
    let page: Int?
    let results: [MoviesTVShowResult]?
    let totalPages, totalResults: Int?

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
