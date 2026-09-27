//
//  DiscoverModelTests.swift
//  CinemaTVTests
//

import Foundation
import SwiftData
import Testing
import CinemaTVCore
@testable import CinemaTV

// URLProtocol routes requests through locked shared stub state. Serializing
// this suite prevents one test from replacing another test's responses.
@Suite("Discover sessions and pagination", .serialized)
@MainActor
struct DiscoverModelTests {
    @Test("Saving keeps the movie and scroll position in the feed")
    func savingPreservesVisibleMovie() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = WatchlistStore(container: container)
        let item = MediaItem(id: 603, title: "Matrix", overview: "", posterPath: nil, backdropPath: nil, voteAverage: 8, releaseDate: nil, mediaType: .movie)
        let model = DiscoverModel(previewDeck: [item])
        model.decide(item, wanted: true, store: store)
        #expect(model.deck == [item])
        #expect(model.visibleItemID == item.id)
        #expect(store.isInWatchlist(movieID: item.id))
        #expect(!model.canUndo)
    }

    @Test("Undoing a skip preserves an existing saved movie")
    func undoSkipPreservesSavedMovie() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = WatchlistStore(container: container)
        let item = MediaItem(id: 603, title: "Matrix", overview: "", posterPath: nil, backdropPath: nil, voteAverage: 8, releaseDate: nil, mediaType: .movie)
        let model = DiscoverModel(previewDeck: [item])
        try store.addToWatchlist(item)
        model.decide(item, wanted: true, store: store)
        model.decide(item, wanted: false, store: store)
        model.undoSkip()
        #expect(model.deck == [item])
        #expect(store.isInWatchlist(movieID: item.id))
    }

    @Test("Saving an already watched movie does not return it to Want to Watch")
    func savingWatchedMovieDoesNotCreatePendingEntry() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = WatchlistStore(container: container)
        let item = MediaItem(id: 603, title: "Matrix", overview: "", posterPath: nil, backdropPath: nil, voteAverage: 8, releaseDate: "1999-03-31", mediaType: .movie)
        try store.markWatched(item)
        let model = DiscoverModel(previewDeck: [item])

        #expect(!model.decide(item, wanted: true, store: store))
        #expect(model.deck == [item])
        #expect(!store.isInWatchlist(movieID: item.id))
        #expect(store.isWatched(movieID: item.id))
    }

    @Test("Every fresh session starts with a different movie")
    func freshSessionsDoNotRepeatTheOpeningMovie() async throws {
        let fixture = try DiscoverTestFixture(responses: [
            1: [try discoverPage(1, totalPages: 1, movieIDs: [1, 2])]
        ])
        defer { fixture.cleanUp() }
        var previousOpeningMovieID: Int?

        // Two candidates expose shuffling that does not protect the previous
        // opening; the contract applies to every pair of adjacent sessions.
        for _ in 0..<8 {
            let model = DiscoverModel(defaults: fixture.defaults)
            await model.loadInitial(client: fixture.client)
            let openingMovieID = try #require(model.deck.first?.id)

            #expect(openingMovieID != previousOpeningMovieID)
            #expect(Set(model.deck.map(\.id)) == Set([1, 2]))
            #expect(model.visibleItemID == openingMovieID)
            previousOpeningMovieID = openingMovieID
        }
    }

    @Test("The initial response contains unique movies only")
    func initialLoadRemovesDuplicateMovieIDs() async throws {
        let fixture = try DiscoverTestFixture(responses: [
            1: [try discoverPage(
                1,
                totalPages: 1,
                movieIDs: [1, 2, 2, 3, 1],
                otherItems: [
                    ["id": 90, "name": "A series", "media_type": "tv"],
                    ["id": 91, "name": "An actor", "media_type": "person"]
                ]
            )]
        ])
        defer { fixture.cleanUp() }
        let model = DiscoverModel(defaults: fixture.defaults)

        await model.loadInitial(client: fixture.client)

        #expect(model.deck.count == 3)
        #expect(Set(model.deck.map(\.id)) == Set([1, 2, 3]))
        #expect(model.deck.allSatisfy { $0.mediaType == .movie })
    }

    @Test("Returning to the same session preserves its order and visible movie")
    func repeatedInitialLoadPreservesSession() async throws {
        let fixture = try DiscoverTestFixture(responses: [
            1: [try discoverPage(1, totalPages: 1, movieIDs: Array(1...20))]
        ])
        defer { fixture.cleanUp() }
        let model = DiscoverModel(defaults: fixture.defaults)
        await model.loadInitial(client: fixture.client)
        let originalOrder = model.deck.map(\.id)
        let visibleMovieID = try #require(model.deck.dropFirst(8).first?.id)
        model.visibleItemID = visibleMovieID

        await model.loadInitial(client: fixture.client)

        #expect(model.deck.map(\.id) == originalOrder)
        #expect(model.visibleItemID == visibleMovieID)
        #expect(DiscoverStubState.shared.requestedPages == [1])
    }

    @Test("Scrolling into the last four movies loads more without any decisions")
    func visiblePositionTriggersPaginationWithoutDecisions() async throws {
        let fixture = try DiscoverTestFixture(responses: [
            1: [try discoverPage(1, totalPages: 2, movieIDs: Array(1...20))],
            2: [try discoverPage(2, totalPages: 2, movieIDs: Array(21...25))]
        ])
        defer { fixture.cleanUp() }
        let model = DiscoverModel(defaults: fixture.defaults)
        await model.loadInitial(client: fixture.client)
        let originalOrder = model.deck.map(\.id)
        try #require(originalOrder.count == 20)
        model.visibleItemID = originalOrder[15]

        await model.loadMoreIfNeeded(client: fixture.client)
        #expect(DiscoverStubState.shared.requestedPages == [1])

        model.visibleItemID = originalOrder[16]
        await model.loadMoreIfNeeded(client: fixture.client)

        #expect(model.deck.count == 25)
        #expect(Array(model.deck.prefix(20).map(\.id)) == originalOrder)
        #expect(Set(model.deck.suffix(5).map(\.id)) == Set(21...25))
        #expect(model.visibleItemID == originalOrder[16])
        #expect(model.history.isEmpty)
        #expect(DiscoverStubState.shared.requestedPages == [1, 2])
    }

    @Test("Duplicate-only pages are skipped until useful movies or exhaustion", arguments: [true, false])
    func paginationSkipsUnusablePages(findsMoreMovies: Bool) async throws {
        let lastPageIDs = findsMoreMovies ? [21, 21, 22, 1] : [1, 1, 2]
        let fixture = try DiscoverTestFixture(responses: [
            1: [try discoverPage(1, totalPages: 3, movieIDs: Array(1...20))],
            2: [try discoverPage(
                2,
                totalPages: 3,
                movieIDs: [1, 1, 2],
                otherItems: [["id": 90, "name": "A series", "media_type": "tv"]]
            )],
            3: [try discoverPage(3, totalPages: 3, movieIDs: lastPageIDs)]
        ])
        defer { fixture.cleanUp() }
        let model = DiscoverModel(defaults: fixture.defaults)
        await model.loadInitial(client: fixture.client)
        let originalOrder = model.deck.map(\.id)
        let visibleMovieID = try #require(originalOrder.last)
        model.visibleItemID = visibleMovieID

        await model.loadMoreIfNeeded(client: fixture.client)

        let expectedIDs = findsMoreMovies ? Set(1...22) : Set(1...20)
        #expect(Set(model.deck.map(\.id)) == expectedIDs)
        #expect(model.deck.count == expectedIDs.count)
        #expect(Array(model.deck.prefix(20).map(\.id)) == originalOrder)
        #expect(model.visibleItemID == originalOrder.last)
        #expect(model.paginationError == nil)
        #expect(DiscoverStubState.shared.requestedPages == [1, 2, 3])

        await model.loadMoreIfNeeded(client: fixture.client)
        #expect(DiscoverStubState.shared.requestedPages == [1, 2, 3])
    }

    @Test("Retrying a failed next page keeps the existing deck and position")
    func paginationRetryPreservesSession() async throws {
        let fixture = try DiscoverTestFixture(responses: [
            1: [try discoverPage(1, totalPages: 2, movieIDs: Array(1...20))],
            2: [.httpError(503), try discoverPage(2, totalPages: 2, movieIDs: Array(21...25))]
        ])
        defer { fixture.cleanUp() }
        let model = DiscoverModel(defaults: fixture.defaults)
        await model.loadInitial(client: fixture.client)
        let originalOrder = model.deck.map(\.id)
        let visibleMovieID = try #require(originalOrder.last)
        model.visibleItemID = visibleMovieID

        await model.loadMoreIfNeeded(client: fixture.client)

        #expect(model.paginationError != nil)
        #expect(model.deck.map(\.id) == originalOrder)
        #expect(model.visibleItemID == originalOrder.last)
        if case .loaded = model.state {} else {
            Issue.record("Pagination failure must leave the current deck usable")
        }

        await model.retry(client: fixture.client)

        #expect(model.paginationError == nil)
        #expect(model.deck.count == 25)
        #expect(Array(model.deck.prefix(20).map(\.id)) == originalOrder)
        #expect(model.visibleItemID == originalOrder.last)
        #expect(DiscoverStubState.shared.requestedPages == [1, 2, 2])
    }

    @Test("An initial request failure can still be retried")
    func initialFailureCanBeRetried() async throws {
        let fixture = try DiscoverTestFixture(responses: [
            1: [.httpError(503), try discoverPage(1, totalPages: 1, movieIDs: [1, 2, 3])]
        ])
        defer { fixture.cleanUp() }
        let model = DiscoverModel(defaults: fixture.defaults)
        await model.loadInitial(client: fixture.client)
        if case .failed = model.state {} else {
            Issue.record("An initial network failure should expose the retry state")
        }

        await model.retry(client: fixture.client)

        #expect(Set(model.deck.map(\.id)) == Set([1, 2, 3]))
        #expect(model.visibleItemID == model.deck.first?.id)
        if case .loaded = model.state {} else {
            Issue.record("A successful retry should load the initial deck")
        }
        #expect(DiscoverStubState.shared.requestedPages == [1, 1])
    }

    @Test("Cancellation does not surface as a feed error", arguments: [false, true])
    func cancellationDoesNotFailTheFeed(duringPagination: Bool) async throws {
        let requests = AsyncStream<Int>.makeStream()
        defer { requests.continuation.finish() }
        let responses: [Int: [DiscoverStubResponse]] = duringPagination
            ? [1: [try discoverPage(1, totalPages: 2, movieIDs: Array(1...20))], 2: [.pending]]
            : [1: [.pending]]
        let fixture = try DiscoverTestFixture(responses: responses, requestEvents: requests.continuation)
        defer { fixture.cleanUp() }
        let model = DiscoverModel(defaults: fixture.defaults)
        if duringPagination {
            await model.loadInitial(client: fixture.client)
            model.visibleItemID = try #require(model.deck.last?.id)
        }
        let originalOrder = model.deck.map(\.id)
        let visibleMovieID = model.visibleItemID
        let task = Task {
            if duringPagination {
                await model.loadMoreIfNeeded(client: fixture.client)
            } else {
                await model.loadInitial(client: fixture.client)
            }
        }

        // Await the actual URLProtocol request before cancelling; no sleeps
        // or assumptions about URLSession scheduling are necessary.
        for await page in requests.stream {
            if page == (duringPagination ? 2 : 1) { break }
        }
        if duringPagination {
            model.cancelLoading()
        } else {
            task.cancel()
        }
        await task.value

        #expect(model.deck.map(\.id) == originalOrder)
        #expect(model.visibleItemID == visibleMovieID)
        #expect(model.paginationError == nil)
        switch model.state {
        case .idle:
            #expect(!duringPagination)
        case .loaded:
            #expect(duringPagination)
        case .loading, .failed:
            Issue.record("Cancellation must finish loading without displaying an error")
        }
    }
}

private struct DiscoverTestFixture {
    let defaults: UserDefaults
    let client: TMDBClient
    private let defaultsSuiteName: String
    private let session: URLSession

    init(
        responses: [Int: [DiscoverStubResponse]],
        requestEvents: AsyncStream<Int>.Continuation? = nil
    ) throws {
        defaultsSuiteName = "DiscoverModelTests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: defaultsSuiteName))
        DiscoverStubState.shared.install(responses: responses, requestEvents: requestEvents)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DiscoverURLProtocol.self]
        session = URLSession(configuration: configuration)
        client = TMDBClient(
            configuration: TMDBConfiguration(apiKey: "discover-test-key"),
            session: session
        )
    }

    func cleanUp() {
        session.invalidateAndCancel()
        defaults.removePersistentDomain(forName: defaultsSuiteName)
    }
}

private func discoverPage(
    _ page: Int,
    totalPages: Int,
    movieIDs: [Int],
    otherItems: [[String: Any]] = []
) throws -> DiscoverStubResponse {
    let movies: [[String: Any]] = movieIDs.map { ["id": $0, "title": "Movie \($0)"] }
    let data = try JSONSerialization.data(withJSONObject: [
        "page": page,
        "results": movies + otherItems,
        "total_pages": totalPages,
        "total_results": totalPages * 20
    ])
    return .page(data)
}

private enum DiscoverStubResponse: Sendable {
    case page(Data)
    case httpError(Int)
    case pending
}

private final class DiscoverStubState: @unchecked Sendable {
    static let shared = DiscoverStubState()
    private let lock = NSLock()
    private var responses: [Int: [DiscoverStubResponse]] = [:]
    private var requestEvents: AsyncStream<Int>.Continuation?
    private var pages: [Int] = []

    var requestedPages: [Int] { lock.withLock { pages } }

    func install(
        responses: [Int: [DiscoverStubResponse]],
        requestEvents: AsyncStream<Int>.Continuation?
    ) {
        lock.withLock {
            self.responses = responses
            self.requestEvents = requestEvents
            pages = []
        }
    }

    func response(for page: Int) -> DiscoverStubResponse? {
        let result = lock.withLock { () -> (DiscoverStubResponse?, AsyncStream<Int>.Continuation?) in
            pages.append(page)
            let response = responses[page]?.first
            if (responses[page]?.count ?? 0) > 1 {
                responses[page]?.removeFirst()
            }
            return (response, requestEvents)
        }
        result.1?.yield(page)
        return result.0
    }
}

private final class DiscoverURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let page = query?.first { $0.name == "page" }?.value.flatMap(Int.init) ?? 1
        guard let stub = DiscoverStubState.shared.response(for: page) else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }
        let status: Int
        let body: Data
        switch stub {
        case .page(let data):
            status = 200
            body = data
        case .httpError(let code):
            status = code
            body = Data()
        case .pending:
            return
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("Discover inline trailer")
@MainActor
struct DiscoverTrailerTests {
    private func item(_ id: Int) -> MediaItem {
        MediaItem(id: id, title: "Movie", overview: "", posterPath: nil, backdropPath: nil,
                  voteAverage: 8, releaseDate: nil, mediaType: .movie)
    }

    private func response(_ id: Int = 1, videos: String = "") throws -> VideosResponse {
        try JSONDecoder().decode(VideosResponse.self, from: Data("{\"id\":\(id),\"results\":[\(videos)]}".utf8))
    }

    private var trailerJSON: String {
        "{\"id\":\"trailer\",\"key\":\"abcdefghijk\",\"name\":\"Trailer\",\"site\":\"YouTube\",\"type\":\"Trailer\",\"official\":true}"
    }

    @Test("Choose an official YouTube trailer over clips and unofficial trailers")
    func selectsOfficialTrailer() {
        let clip = Video(id: "clip", key: "a", name: "Clip", site: "YouTube", type: "Clip", official: true)
        let unofficial = Video(id: "fan", key: "b", name: "Trailer", site: "YouTube", type: "Trailer", official: false)
        let official = Video(id: "official", key: "c", name: "Trailer", site: "YouTube", type: "Trailer", official: true)
        #expect(DiscoverTrailerModel.preferredTrailer(in: [clip, unofficial, official]) == official)
        #expect(DiscoverTrailerModel.preferredTrailer(in: [clip]) == nil)
    }

    @Test("The cover remains until the matching player is ready")
    func waitsForMatchingPlayerReadiness() async throws {
        let model = DiscoverTrailerModel()
        defer { model.close() }
        let payload = try response(videos: trailerJSON)
        model.play(item(1), fetch: { payload })
        await settle(model)
        let video = try #require(model.video)
        #expect(!model.isReady)
        let wrong = Video(id: "wrong", key: "wrong", name: "", site: "YouTube", type: "Trailer", official: true)
        model.playerReady(for: wrong, playbackID: model.playbackID)
        #expect(!model.isReady)
        model.playerReady(for: video, playbackID: model.playbackID)
        #expect(model.isReady)
        model.close()
        model.playerReady(for: video, playbackID: model.playbackID)
        #expect(model.phase == .idle)
        #expect(model.movieID == nil)
    }

    @Test("Callbacks from a closed player cannot change a new playback of the same trailer")
    func rejectsOldPlayerCallbacks() async throws {
        let model = DiscoverTrailerModel()
        defer { model.close() }
        let payload = try response(videos: trailerJSON)
        model.play(item(1), fetch: { payload })
        await settle(model)
        let oldID = model.playbackID
        let video = try #require(model.video)
        model.close()
        model.play(item(1), fetch: { payload })
        await settle(model)
        model.playerReady(for: video, playbackID: oldID)
        #expect(!model.isReady)
        model.playerFailed(for: video, playbackID: oldID)
        #expect(model.phase == .preparing(video))
        model.playerReady(for: video, playbackID: model.playbackID)
        #expect(model.isReady)
    }

    @Test("Repeated taps use one request and missing trailers expose a recoverable state")
    func coalescesTapsAndHandlesMissingTrailer() async throws {
        let model = DiscoverTrailerModel()
        defer { model.close() }
        let payload = try response()
        var requests = 0
        let fetch: @MainActor () async throws -> VideosResponse = { requests += 1; return payload }
        model.play(item(1), fetch: fetch)
        model.play(item(1), fetch: fetch)
        await settle(model)
        #expect(requests == 1)
        #expect(model.phase == .unavailable)
    }

    @Test("Network errors keep the cover and allow retry")
    func networkErrorAndRetry() async throws {
        let model = DiscoverTrailerModel()
        defer { model.close() }
        model.play(item(1), fetch: { throw URLError(.notConnectedToInternet) })
        await settle(model)
        #expect(model.phase == .failed)
        #expect(model.video == nil)
        let payload = try response(videos: trailerJSON)
        model.play(item(1), fetch: { payload })
        await settle(model)
        #expect(model.video != nil)
    }

    @Test("An old request cannot replace a newer movie even when it ignores cancellation")
    func rejectsStaleResponse() async throws {
        let model = DiscoverTrailerModel()
        defer { model.close() }
        let started = AsyncStream<Void>.makeStream()
        var completion: CheckedContinuation<VideosResponse, Never>?
        let payload = try response(videos: trailerJSON)
        model.play(item(1), fetch: {
            await withCheckedContinuation { continuation in
                completion = continuation
                started.continuation.yield(())
                started.continuation.finish()
            }
        })
        for await _ in started.stream { break }
        model.play(item(2), fetch: { payload })
        completion?.resume(returning: payload)
        await settle(model)
        #expect(model.movieID == 2)
        #expect(model.video?.id == "trailer")
    }

    /// Bounded executor turns, with an assertion instead of wall-clock sleeps.
    private func settle(_ model: DiscoverTrailerModel) async {
        for _ in 0..<1_000 {
            if model.phase != .loading { return }
            await Task.yield()
        }
        Issue.record("Trailer request did not finish")
    }
}
