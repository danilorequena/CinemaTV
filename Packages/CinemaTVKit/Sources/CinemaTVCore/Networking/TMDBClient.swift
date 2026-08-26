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
        query: String? = nil,
        parameters: [String: String]? = nil
    ) async throws(TMDBError) -> T {
        let url = try makeURL(endpoint: endpoint, page: page, query: query, parameters: parameters)

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

    func makeURL(
        endpoint: TMDBEndpoint,
        page: Int? = nil,
        query: String? = nil,
        parameters: [String: String]? = nil
    ) throws(TMDBError) -> URL {
        guard var components = URLComponents(
            url: configuration.baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw TMDBError.invalidEndpoint
        }

        // Idioma segue o locale do aparelho; região vem do TMDBRegion
        // (override do usuário ou região do aparelho) — independentes:
        // trocar a região não deve trocar o idioma das sinopses.
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let languageRegion = Locale.current.region?.identifier ?? "US"
        let region = TMDBRegion.current

        var items = [
            URLQueryItem(name: "api_key", value: configuration.apiKey),
            URLQueryItem(name: "language", value: "\(language)-\(languageRegion)"),
            URLQueryItem(name: "region", value: region),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        if let page {
            items.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let query {
            items.append(URLQueryItem(name: "query", value: query))
        }
        // Extras do endpoint (ex.: with_genres do discover), em ordem
        // estável para URLs determinísticas nos testes.
        if let parameters {
            for (name, value) in parameters.sorted(by: { $0.key < $1.key }) {
                items.append(URLQueryItem(name: name, value: value))
            }
        }
        components.queryItems = items

        guard let url = components.url else {
            throw TMDBError.invalidEndpoint
        }
        return url
    }
}
