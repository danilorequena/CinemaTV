//
//  Movie.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

// MARK: - DiscoverMovies
struct DiscoverMovies: Codable {
    let page: Int?
    let results: [MoviesTVShowResult]
    let totalPages, totalResults: Int?

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Result
struct MoviesTVShowResult: Codable, Identifiable, Hashable {
    let adult: Bool?
    let backdropPath: String?
    let genreIDS: [Int]?
    let id: Int?
    let originalTitle, overview: String?
    let popularity: Double?
    let posterPath: String?
    let releaseDate: String?
    let title: String?
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?
    let name: String?
    let originalName: String?

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIDS = "genre_ids"
        case id
        case originalTitle = "original_title"
        case overview, popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title, video
        case name
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case originalName = "original_name"
    }
}

extension DiscoverMovies {
        static var stubbedMovies: MoviesTVShowResult {
            let response: DiscoverMovies? = try? Bundle.main.loadAndDecodeJSON(fileName: "movie_tvshow")
            return response!.results.first!
        }
}
