//
//  WatchProviders.swift
//  CinemaTV
//
//  Created by Danilo Requena on 11/12/22.
//

import Foundation

// MARK: - WatchProviders
struct WatchProviders: Codable {
    let id: Int?
    let results: ProvidersResults?
}

// MARK: - Results
struct ProvidersResults: Codable {
    let br: ProvidersData?

    enum CodingKeys: String, CodingKey {
        case br = "BR"
    }
}

// MARK: - AE
struct ProvidersData: Codable {
    let link: String?
    let rent, buy, flatrate: [WatchProvider]?
}

// MARK: - Buy
struct WatchProvider: Codable, Identifiable {
    let logoPath: String?
    let id: Int?
    let providerName: String?
    let displayPriority: Int?

    enum CodingKeys: String, CodingKey {
        case logoPath = "logo_path"
        case id = "provider_id"
        case providerName = "provider_name"
        case displayPriority = "display_priority"
    }
}
