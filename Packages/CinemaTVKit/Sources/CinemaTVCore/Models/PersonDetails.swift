//
//  PersonDetails.swift
//  CinemaTVKit
//

import Foundation

public struct PersonDetails: Identifiable, Hashable, Sendable, Decodable {
    public let id: Int
    public let name: String
    public let biography: String?
    public let birthday: String?
    public let deathday: String?
    public let placeOfBirth: String?
    public let profilePath: String?
    public let knownForDepartment: String?

    public var profileURL: URL? { TMDBImage.url(path: profilePath, size: .poster) }
}

/// combined_credits de uma pessoa: filmes e séries em que participou.
public struct PersonCredits: Decodable, Sendable {
    public let id: Int
    public let cast: [MediaItem]
}
