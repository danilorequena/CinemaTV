import Foundation

public enum StreamingMediaKind: Sendable {
    case movie
    case tv
}

/// Filters titles by availability today. TMDB does not expose when a title
/// first entered a particular provider's catalog.
public struct StreamingAvailabilityQuery: Sendable {
    public let kind: StreamingMediaKind
    public let region: String
    public let providerID: Int
    public let today: String

    public init(kind: StreamingMediaKind, region: String, providerID: Int, today: String) {
        self.kind = kind
        self.region = region
        self.providerID = providerID
        self.today = today
    }

    public var catalogEndpoint: TMDBEndpoint {
        switch kind {
        case .movie: .movieWatchProviderCatalog
        case .tv: .tvWatchProviderCatalog
        }
    }

    public var discoverEndpoint: TMDBEndpoint {
        switch kind {
        case .movie: .discoverMovies
        case .tv: .discoverTVShows
        }
    }

    public var catalogParameters: [String: String] {
        ["watch_region": region]
    }

    public var parameters: [String: String] {
        var parameters = [
            "watch_region": region,
            "with_watch_providers": String(providerID),
            "with_watch_monetization_types": "flatrate"
        ]
        switch kind {
        case .movie:
            parameters["sort_by"] = "primary_release_date.desc"
            parameters["primary_release_date.lte"] = today
        case .tv:
            parameters["sort_by"] = "first_air_date.desc"
            parameters["first_air_date.lte"] = today
        }
        return parameters
    }
}
