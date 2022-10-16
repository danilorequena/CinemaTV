//
//  CreditByPerson.swift
//  CinemaTV
//
//  Created by Danilo Requena on 15/10/22.
//

import Foundation

// MARK: - CreditsByPerson
struct CreditsByPerson: Codable {
    let cast, crew: [Cast]?
    let id: Int?
}

// MARK: - Cast
struct Cast: Codable, Identifiable {
    let adult: Bool?
    let backdropPath: String?
    let id: Int?
    let originalTitle, overview: String?
    let popularity: Double?
    let posterPath: String?
    let releaseDate, title: String?
    let voteAverage: Double?
    let voteCount: Int?
    let character, creditID: String?

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case id
        case originalTitle = "original_title"
        case overview, popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case character
        case creditID = "credit_id"
    }
}

enum Department: String, Codable {
    case crew = "Crew"
    case production = "Production"
}

enum Job: String, Codable {
    case executiveProducer = "Executive Producer"
    case producer = "Producer"
    case thanks = "Thanks"
}

enum OriginalLanguage: String, Codable {
    case en = "en"
    case fr = "fr"
    case ja = "ja"
}

