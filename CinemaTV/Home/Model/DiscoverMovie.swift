//
//  Movie.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

// MARK: - Movie
struct DiscoverMovie: Codable {
    let page: Int
    let results: [MoviesResult]
    let totalPages, totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Result
struct MoviesResult: Codable, Identifiable {
    let backdropPath: String?
    let genreIDS: [Int]
    let id: Int
    let originalTitle, overview: String
    let popularity: Double
    let posterPath: String
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
    
        case backdropPath = "backdrop_path"
        case genreIDS = "genre_ids"
        case id
        case originalTitle = "original_title"
        case overview, popularity
        case posterPath = "poster_path"
        case title, video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}


