//
//  NowPlayingMovies.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/04/22.
//

import Foundation

// MARK: - NowPlayingMovies
struct NowPlayingMovies: Codable {
    let dates: NowPlayingDates
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
struct NowPlayingDates: Codable {
    let maximum, minimum: String
}
