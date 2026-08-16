//
//  TMDBClient.swift
//  CinemaTVKit
//
//  Substitui as quatro pilhas de callbacks legadas (Service, MovieStore,
//  TVShowStore, PersonStore) por um único método genérico async.
//

import Foundation

public struct TMDBClient: Sendable {
    public let configuration: TMDBConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(configuration: TMDBConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func fetch<T: Decodable & Sendable>(
        _ endpoint: TMDBEndpoint,
        page: Int? = nil,
        query: String? = nil
    ) async throws(TMDBError) -> T {
        let url = try makeURL(endpoint: endpoint, page: page, query: query)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw TMDBError.transport(description: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse(statusCode: nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw TMDBError.invalidResponse(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TMDBError.decodingFailed(description: String(describing: error))
        }
    }

    func makeURL(endpoint: TMDBEndpoint, page: Int? = nil, query: String? = nil) throws(TMDBError) -> URL {
        guard var components = URLComponents(
            url: configuration.baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw TMDBError.invalidEndpoint
        }

        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let region = Locale.current.language.region?.identifier ?? "US"

        var items = [
            URLQueryItem(name: "api_key", value: configuration.apiKey),
            URLQueryItem(name: "language", value: "\(language)-\(region)"),
            URLQueryItem(name: "region", value: region),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        if let page {
            items.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let query {
            items.append(URLQueryItem(name: "query", value: query))
        }
        components.queryItems = items

        guard let url = components.url else {
            throw TMDBError.invalidEndpoint
        }
        return url
    }
}
