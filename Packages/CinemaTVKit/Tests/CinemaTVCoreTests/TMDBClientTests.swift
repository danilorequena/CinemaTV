//
//  TMDBClientTests.swift
//  CinemaTVKit
//

import Foundation
import Testing
@testable import CinemaTVCore

// Serializada: MockURLProtocol.stub é estado compartilhado entre os testes de fetch.
@Suite(.serialized) struct TMDBClientTests {
    private let client = TMDBClient(configuration: TMDBConfiguration(apiKey: "test-key"))

    @Test func buildsURLWithDefaultQueryItems() throws {
        let url = try client.makeURL(endpoint: .discoverMovies)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.path.hasSuffix("discover/movie"))
        let items = try #require(components.queryItems)
        #expect(items.contains(URLQueryItem(name: "api_key", value: "test-key")))
        #expect(items.contains(URLQueryItem(name: "include_adult", value: "false")))
        #expect(items.contains { $0.name == "language" })
        #expect(items.contains { $0.name == "region" })
    }

    @Test func buildsURLWithPageAndQuery() throws {
        let url = try client.makeURL(endpoint: .searchMovies, page: 2, query: "matrix")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)

        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
        #expect(items.contains(URLQueryItem(name: "query", value: "matrix")))
    }

    @Test func fetchDecodesSuccessfulResponse() async throws {
        let json = """
        {"page": 1, "results": [], "total_pages": 1, "total_results": 0}
        """
        let session = makeMockSession(statusCode: 200, body: json)
        let client = TMDBClient(
            configuration: TMDBConfiguration(apiKey: "test-key"),
            session: session
        )

        let page: PagedResponse<MediaItem> = try await client.fetch(.popularMovies)
        #expect(page.results.isEmpty)
        #expect(!page.hasMorePages)
    }

    @Test func fetchThrowsOnHTTPError() async throws {
        let session = makeMockSession(statusCode: 404, body: "{}")
        let client = TMDBClient(
            configuration: TMDBConfiguration(apiKey: "test-key"),
            session: session
        )

        await #expect(throws: TMDBError.invalidResponse(statusCode: 404)) {
            let _: PagedResponse<MediaItem> = try await client.fetch(.popularMovies)
        }
    }

    private func makeMockSession(statusCode: Int, body: String) -> URLSession {
        MockURLProtocol.stub = (statusCode, Data(body.utf8))
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var stub: (statusCode: Int, data: Data)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = Self.stub, let url = request.url else { return }
        let response = HTTPURLResponse(
            url: url,
            statusCode: stub.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
