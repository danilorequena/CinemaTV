//
//  CastModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 26/11/21.
//

import Foundation

// MARK: - Cast
struct CastModel: Codable {
    let id: Int
    let cast: [CastList]?
    let crew: [Crew]?
}

// MARK: - CastElement
struct CastList: Codable, Identifiable {
    let castID: Int?
    let character, creditID: String?
    let gender, id: Int?
    let name: String?
    let order: Int?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case castID = "cast_id"
        case character
        case creditID = "credit_id"
        case gender, id, name, order
        case profilePath = "profile_path"
    }
}

// MARK: - Crew
struct Crew: Codable {
    let creditID, department: String?
    let gender, id: Int?
    let job, name: String?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case creditID = "credit_id"
        case department, gender, id, job, name
        case profilePath = "profile_path"
    }
}

