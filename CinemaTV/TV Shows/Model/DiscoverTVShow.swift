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

// MARK: - Result
struct TVShowResult: Codable, Identifiable {
    let title: String?
    let backdropPath, firstAirDate: String?
    let genreIDS: [Int]?
    let id: Int?
    let name: String?
    let originCountry: [String]?
    let originalLanguage, originalName, overview: String?
    let popularity: Double?
    let posterPath: String?
    let voteAverage: Double?
    let voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case genreIDS = "genre_ids"
        case id, name, title
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview, popularity
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

