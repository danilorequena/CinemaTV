//
//  WatchProviders.swift
//  CinemaTVKit
//

import Foundation

public struct WatchProvidersResponse: Decodable, Sendable {
    public let id: Int
    public let results: [String: RegionProviders]

    /// Provedores da região atual do usuário, com fallback para US.
    public var currentRegion: RegionProviders? {
        let region = Locale.current.language.region?.identifier ?? "US"
        return results[region] ?? results["US"]
    }
}

public struct RegionProviders: Decodable, Sendable {
    public let link: String?
    public let flatrate: [WatchProvider]?
    public let rent: [WatchProvider]?
    public let buy: [WatchProvider]?
}

public struct WatchProvider: Identifiable, Hashable, Sendable, Decodable {
    public let providerId: Int
    public let providerName: String
    public let logoPath: String?

    public var id: Int { providerId }
    public var logoURL: URL? { TMDBImage.url(path: logoPath, size: .profile) }

    public init(providerId: Int, providerName: String, logoPath: String?) {
        self.providerId = providerId
        self.providerName = providerName
        self.logoPath = logoPath
    }
}
