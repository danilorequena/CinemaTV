//
//  UpcomingMovies.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/04/22.
//

import Foundation

// MARK: - UpcomingMovies
struct UpcomingMovies: Codable {
    let dates: Dates
    let page: Int
    let results: [MovieResult]
    let totalPages, totalResults: Int

    enum CodingKeys: String, CodingKey {
        case dates, page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Dates
struct Dates: Codable {
    let maximum, minimum: String
}
