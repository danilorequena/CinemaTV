//
//  TopVotedMovies.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/04/22.
//

import Foundation

// MARK: - TopVotedMovies
struct TopVotedMovies: Codable {
    let page: Int
    let results: [MovieResult]
    let totalPages, totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
