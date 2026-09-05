import Foundation
import SwiftData
import Testing
import CinemaTVCore

@Suite struct TraktDecodingTests {
    @Test func usesTMDBIDAsCanonicalIdentity() throws {
        let data = Data("""
        {
          "listed_at": "2023-11-14T22:13:20.000Z",
          "movie": {
            "title": "Titanic",
            "year": 1997,
            "ids": { "trakt": 122, "slug": "titanic-1997", "imdb": "tt0120338", "tmdb": 597 }
          }
        }
        """.utf8)

        let item = try JSONDecoder.trakt.decode(TraktWatchlistItem.self, from: data)

        #expect(item.canonicalTMDBID == 597)
        #expect(item.listedAt == Date(timeIntervalSince1970: 1_700_000_000))
    }
}

@Suite(.serialized) struct TraktClientRequestTests {
    @Test func authenticatedRequestContainsRequiredHeadersAndPagination() throws {
        let client = TraktClient(configuration: TraktConfiguration(
            clientID: "client-id",
            clientSecret: "secret",
            redirectURI: "cinematv://trakt-auth"
        ))

        let request = try client.makeRequest(
            endpoint: .watchedMovies,
            accessToken: "access-token",
            page: 3,
            limit: 250
        )

        #expect(request.url?.absoluteString == "https://api.trakt.tv/sync/watched/movies?page=3&limit=250&extended=min")
        #expect(request.value(forHTTPHeaderField: "trakt-api-key") == "client-id")
        #expect(request.value(forHTTPHeaderField: "trakt-api-version") == "2")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
    }

    @Test func fetchAllTraversesEveryPaginationHeaderPage() async throws {
        TraktMockURLProtocol.responses = [
            (200, ["X-Pagination-Page-Count": "2"], Data("""
            [{"listed_at":"2023-11-14T22:13:20.000Z","movie":{"title":"Titanic","year":1997,"ids":{"trakt":122,"slug":"titanic-1997","imdb":"tt0120338","tmdb":597}}}]
            """.utf8)),
            (200, ["X-Pagination-Page-Count": "2"], Data("[]".utf8))
        ]
        TraktMockURLProtocol.requestedPages = []
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [TraktMockURLProtocol.self]
        let client = TraktClient(
            configuration: TraktConfiguration(
                clientID: "client-id",
                clientSecret: "secret",
                redirectURI: "cinematv://trakt-auth"
            ),
            session: URLSession(configuration: sessionConfiguration)
        )

        let items: [TraktWatchlistItem] = try await client.fetchAll(
            .watchlistMovies,
            accessToken: "token"
        )

        #expect(items.map(\.canonicalTMDBID) == [597])
        #expect(TraktMockURLProtocol.requestedPages == ["1", "2"])
    }
}

final class TraktMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [(Int, [String: String], Data)] = []
    nonisolated(unsafe) static var requestedPages: [String] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let page = request.url.flatMap {
            URLComponents(url: $0, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "page" })?.value
        }
        if let page { Self.requestedPages.append(page) }
        guard !Self.responses.isEmpty, let url = request.url else { return }
        let (status, headers, data) = Self.responses.removeFirst()
        let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: nil,
            headerFields: headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
@Suite struct TraktMovieMergeTests {
    @Test func watchedImportIsIdempotentAndWinsOverWatchlist() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = WatchlistStore(container: container)
        let movie = MediaItem(
            id: 597,
            title: "Titanic",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.9,
            releaseDate: "1997-11-18",
            mediaType: .movie
        )
        let watchedAt = Date(timeIntervalSince1970: 1_700_000_000)

        try store.addToWatchlist(movie)
        try store.importWatched(movie, watchedAt: watchedAt)
        try store.importWatched(movie, watchedAt: watchedAt)

        #expect(try store.moviesToWatch().isEmpty)
        let watched = try store.moviesWatched()
        #expect(watched.count == 1)
        #expect(watched.first?.watchedAt == watchedAt)
    }
}
