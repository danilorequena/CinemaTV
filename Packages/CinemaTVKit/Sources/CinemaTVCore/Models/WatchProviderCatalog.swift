import Foundation

public struct WatchProviderCatalogResponse: Decodable, Sendable {
    public let results: [WatchProvider]
}
