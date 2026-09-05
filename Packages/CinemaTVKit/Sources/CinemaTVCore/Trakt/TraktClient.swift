import Foundation

public struct TraktConfiguration: Sendable, Equatable {
    public let clientID: String
    public let clientSecret: String
    public let redirectURI: String
    public let apiBaseURL: URL
    public let authBaseURL: URL

    public init(
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        apiBaseURL: URL = URL(string: "https://api.trakt.tv") ?? URL(filePath: "/"),
        authBaseURL: URL = URL(string: "https://trakt.tv/oauth") ?? URL(filePath: "/")
    ) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.apiBaseURL = apiBaseURL
        self.authBaseURL = authBaseURL
    }

    public static func fromBundle(_ bundle: Bundle = .main) -> TraktConfiguration? {
        guard let url = bundle.url(forResource: "Trakt", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let clientID = values["CLIENT_ID"],
              let clientSecret = values["CLIENT_SECRET"],
              let redirectURI = values["REDIRECT_URI"],
              !clientID.isEmpty, !clientSecret.isEmpty, !redirectURI.isEmpty,
              !clientID.hasPrefix("YOUR_"), !clientSecret.hasPrefix("YOUR_")
        else { return nil }
        return TraktConfiguration(clientID: clientID, clientSecret: clientSecret, redirectURI: redirectURI)
    }
}

public enum TraktEndpoint: Sendable, Equatable {
    case watchlistMovies
    case watchlistShows
    case watchedMovies
    case watchedShows
    case userSettings

    var path: String {
        switch self {
        case .watchlistMovies: "users/me/watchlist/movies"
        case .watchlistShows: "users/me/watchlist/shows"
        case .watchedMovies: "sync/watched/movies"
        case .watchedShows: "sync/watched/shows"
        case .userSettings: "users/settings"
        }
    }

    var extended: String {
        switch self {
        case .watchedShows: "progress"
        default: "min"
        }
    }
}

public enum TraktError: Error, Sendable, Equatable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case http(statusCode: Int)
    case decoding(String)
    case transport(String)
}

public struct TraktClient: Sendable {
    public let configuration: TraktConfiguration
    private let session: URLSession

    public init(configuration: TraktConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func makeRequest(
        endpoint: TraktEndpoint,
        accessToken: String,
        page: Int,
        limit: Int = 250
    ) throws -> URLRequest {
        guard var components = URLComponents(
            url: configuration.apiBaseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        ) else { throw TraktError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "extended", value: endpoint.extended)
        ]
        guard let url = components.url else { throw TraktError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(configuration.clientID, forHTTPHeaderField: "trakt-api-key")
        request.setValue("2", forHTTPHeaderField: "trakt-api-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    public func fetchAll<T: Decodable & Sendable>(
        _ endpoint: TraktEndpoint,
        accessToken: String,
        limit: Int = 250
    ) async throws -> [T] {
        var page = 1
        var accumulated: [T] = []
        while true {
            let request = try makeRequest(
                endpoint: endpoint,
                accessToken: accessToken,
                page: page,
                limit: limit
            )
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                throw TraktError.transport(error.localizedDescription)
            }
            guard let http = response as? HTTPURLResponse else {
                throw TraktError.invalidResponse
            }
            switch http.statusCode {
            case 200..<300:
                break
            case 401:
                throw TraktError.unauthorized
            case 429:
                throw TraktError.rateLimited(
                    retryAfter: http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
                )
            default:
                throw TraktError.http(statusCode: http.statusCode)
            }
            let batch: [T]
            do {
                batch = try JSONDecoder.trakt.decode([T].self, from: data)
            } catch {
                throw TraktError.decoding(String(describing: error))
            }
            accumulated.append(contentsOf: batch)
            let totalPages = http.value(forHTTPHeaderField: "X-Pagination-Page-Count").flatMap(Int.init)
            if batch.isEmpty {
                break
            }
            if let totalPages, page >= totalPages { break }
            page += 1
        }
        return accumulated
    }

    public func fetch<T: Decodable & Sendable>(
        _ endpoint: TraktEndpoint,
        accessToken: String
    ) async throws -> T {
        let request = try makeRequest(
            endpoint: endpoint,
            accessToken: accessToken,
            page: 1,
            limit: 1
        )
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TraktError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw TraktError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 { throw TraktError.unauthorized }
            throw TraktError.http(statusCode: http.statusCode)
        }
        do {
            return try JSONDecoder.trakt.decode(T.self, from: data)
        } catch {
            throw TraktError.decoding(String(describing: error))
        }
    }
}
