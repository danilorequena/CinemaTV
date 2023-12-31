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
//    let createdBy: [CreatedBy]?
//    let episodeRunTime: [Int]?
    let firstAirDate: String?
//    let genres: [JSONAny]?
//    let homepage: String?
    let id: Int?
//    let inProduction: Bool?
//    let languages: [JSONAny]?
//    let lastAirDate: String?
//    let lastEpisodeToAir: LastEpisodeToAir?
    let name: String?
//    let nextEpisodeToAir: JSONNull?
//    let networks: [JSONAny]?
//    let numberOfEpisodes, numberOfSeasons: Int?
//    let originCountry: [String]?
    let originalLanguage, originalName, overview: String?
//    let popularity: Double?
    let posterPath: String?
//    let productionCompanies, productionCountries: [JSONAny]?
    let seasons: [Season]?
//    let spokenLanguages: [JSONAny]?
//    let status, tagline, type: String?
    let voteAverage: Double?
    let voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
//        case createdBy = "created_by"
//        case episodeRunTime = "episode_run_time"
        case firstAirDate = "first_air_date"
//        case genres
//        case homepage
        case id
//        case inProduction = "in_production"
//        case languages
//        case lastAirDate = "last_air_date"
//        case lastEpisodeToAir = "last_episode_to_air"
        case name
//        case nextEpisodeToAir = "next_episode_to_air"
//        case networks
//        case numberOfEpisodes = "number_of_episodes"
//        case numberOfSeasons = "number_of_seasons"
//        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview
//        case popularity
        case posterPath = "poster_path"
//        case productionCompanies = "production_companies"
//        case productionCountries = "production_countries"
        case seasons
//        case spokenLanguages = "spoken_languages"
//        case status, tagline, type
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

// MARK: - CreatedBy
struct CreatedBy: Codable, Identifiable {
    let id: Int?
    let creditID, name: String?
    let gender: Int?
//    let profilePath: JSONNull?

    enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case name, gender
//        case profilePath = "profile_path"
    }
}

// MARK: - LastEpisodeToAir
struct LastEpisodeToAir: Codable, Identifiable {
    let airDate: String?
    let episodeNumber, id: Int?
    let name, overview, productionCode: String?
    let runtime, seasonNumber, showID: Int?
//    let stillPath: JSONNull?
    let voteAverage, voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case id, name, overview
        case productionCode = "production_code"
        case runtime
        case seasonNumber = "season_number"
        case showID = "show_id"
//        case stillPath = "still_path"
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
