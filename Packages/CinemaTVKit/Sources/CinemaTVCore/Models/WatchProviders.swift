//
//  WatchProviders.swift
//  CinemaTVKit
//

import Foundation

public struct WatchProvidersResponse: Decodable, Sendable {
    public let id: Int
    public let results: [String: RegionProviders]

    /// Provedores somente da região efetiva; disponibilidade de outro país
    /// não representa uma opção válida para o usuário.
    public var currentRegion: RegionProviders? {
        results[TMDBRegion.current]
    }
}

public struct RegionProviders: Decodable, Sendable {
    public let link: String?
    public let flatrate: [WatchProvider]?
    public let free: [WatchProvider]?
    public let ads: [WatchProvider]?
    public let rent: [WatchProvider]?
    public let buy: [WatchProvider]?

    public var hasOffers: Bool {
        [flatrate, free, ads, rent, buy].contains { !($0 ?? []).isEmpty }
    }

    /// O link retornado pelo TMDB aponta para sua própria página de
    /// disponibilidade, não diretamente para o aplicativo do provedor.
    public var watchPageURL: URL? {
        guard let link, let url = URL(string: link),
              url.scheme == "https", let host = url.host?.lowercased(),
              host == "themoviedb.org" || host.hasSuffix(".themoviedb.org")
        else { return nil }
        return url
    }
}

public struct WatchProvider: Identifiable, Hashable, Sendable, Decodable {
    public let providerId: Int
    public let providerName: String
    public let logoPath: String?
    public let displayPriority: Int?
    public let displayPriorities: [String: Int]?

    public var id: Int { providerId }
    public var logoURL: URL? { TMDBImage.url(path: logoPath, size: .profile) }

    public init(
        providerId: Int,
        providerName: String,
        logoPath: String?,
        displayPriority: Int? = nil,
        displayPriorities: [String: Int]? = nil
    ) {
        self.providerId = providerId
        self.providerName = providerName
        self.logoPath = logoPath
        self.displayPriority = displayPriority
        self.displayPriorities = displayPriorities
    }
}
