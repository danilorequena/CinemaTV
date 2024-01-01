//
//  DetailTVShow.swift
//  CinemaTV
//
//  Created by Danilo Requena on 30/09/22.
//

import Foundation

// MARK: - DetailTVShow
struct DetailTVShow: Codable, Identifiable {
    let backdropPath: String?
    let firstAirDate: String?
    let id: Int?
    let name: String?
    let originalLanguage, originalName, overview: String?
    let posterPath: String?
    let seasons: [Season]?
    let voteAverage: Double?
    let voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case id
        case name
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview
        case posterPath = "poster_path"
        case seasons
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

// MARK: - CreatedBy
struct CreatedBy: Codable, Identifiable {
    let id: Int?
    let creditID, name: String?
    let gender: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case name, gender
    }
}

// MARK: - LastEpisodeToAir
struct LastEpisodeToAir: Codable, Identifiable {
    let airDate: String?
    let episodeNumber, id: Int?
    let name, overview, productionCode: String?
    let runtime, seasonNumber, showID: Int?
    let voteAverage, voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case id, name, overview
        case productionCode = "production_code"
        case runtime
        case seasonNumber = "season_number"
        case showID = "show_id"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

// MARK: - Season
struct Season: Codable, Identifiable {
    let airDate: String?
    let episodeCount, id: Int?
    let name, overview: String?
    let posterPath: String?
    let seasonNumber: Int?

    enum CodingKeys: String, CodingKey {
        case airDate = "air_date"
        case episodeCount = "episode_count"
        case id, name, overview
        case posterPath = "poster_path"
        case seasonNumber = "season_number"
    }
}
