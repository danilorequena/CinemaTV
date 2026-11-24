import Foundation
import Testing
import CinemaTVCore
@testable import CinemaTV

// Each test installs its own responses in the URLProtocol stub.
@Suite("Streaming catalogs", .serialized)
@MainActor
struct StreamingCatalogModelTests {
    @Test("Pagination keeps the provider filters and the order of unique titles", arguments: [false, true])
    func fetchesNextPageInCatalogOrder(isTV: Bool) async throws {
        let fixture = StreamingCatalogFixture(responses: [
            2: [try page(2, totalPages: 2, ids: [2, 3, 3, 4], isTV: isTV)]
        ])
        defer { fixture.session.invalidateAndCancel() }
        let model = StreamingCatalogModel(
            firstPageItems: [item(2), item(1), item(2)],
            nextPage: 2
        )
        #expect(model.items.map(\.id) == [2, 1])

        await model.loadMore(client: fixture.client, query: query(isTV: isTV))
        await model.loadMore(client: fixture.client, query: query(isTV: isTV))

        #expect(model.items.map(\.id) == [2, 1, 3, 4])
        #expect(model.items.last?.mediaType == (isTV ? .tvShow : .movie))
        #expect(model.nextPage == nil)
        #expect(model.errorMessage == nil)
        let requests = StreamingCatalogStub.shared.requests
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(request.path.hasSuffix(isTV ? "/discover/tv" : "/discover/movie"))
        #expect(request["page"] == "2")
        #expect(request["watch_region"] == "BR")
        #expect(request["with_watch_providers"] == "8")
        #expect(request["with_watch_monetization_types"] == "flatrate")
        #expect(request["sort_by"] == (isTV ? "first_air_date.desc" : "primary_release_date.desc"))
        #expect(request[isTV ? "first_air_date.lte" : "primary_release_date.lte"] == "2026-11-23")
    }

    @Test("Pagination skips duplicate-only and empty pages")
    func skipsPagesWithNoNewTitles() async throws {
        let fixture = StreamingCatalogFixture(responses: [
            2: [try page(2, totalPages: 5, ids: [1, 1])],
            3: [try page(3, totalPages: 5, ids: [])],
            4: [try page(4, totalPages: 5, ids: [2, 1])]
        ])
        defer { fixture.session.invalidateAndCancel() }
        let model = StreamingCatalogModel(firstPageItems: [item(1)], nextPage: 2)

        await model.loadMore(client: fixture.client, query: query())

        #expect(model.items.map(\.id) == [1, 2])
        #expect(model.nextPage == 5)
        #expect(StreamingCatalogStub.shared.requests.compactMap { $0["page"] } == ["2", "3", "4"])
    }

    @Test("Pagination stops at TMDB's request limit when more pages are reported")
    func stopsAtTMDBPageLimit() async throws {
        let fixture = StreamingCatalogFixture(responses: [500: [try page(500, totalPages: 560, ids: [2])]])
        defer { fixture.session.invalidateAndCancel() }
        let model = StreamingCatalogModel(firstPageItems: [item(1)], nextPage: 500)

        await model.loadMore(client: fixture.client, query: query())
        await model.loadMore(client: fixture.client, query: query())

        #expect(model.items.map(\.id) == [1, 2])
        #expect(model.nextPage == nil)
        #expect(StreamingCatalogStub.shared.requests.compactMap { $0["page"] } == ["500"])
    }

    @Test("A failed page can be retried without replacing visible titles", arguments: [false, true])
    func retriesTheFailedPage(receivesWrongPage: Bool) async throws {
        let failedResponse: StreamingCatalogResponse = receivesWrongPage
            ? try page(1, totalPages: 3, ids: [9])
            : .response(status: 503, data: Data())
        let fixture = StreamingCatalogFixture(responses: [
            2: [try page(2, totalPages: 3, ids: [1])],
            3: [failedResponse, try page(3, totalPages: 3, ids: [2])]
        ])
        defer { fixture.session.invalidateAndCancel() }
        let model = StreamingCatalogModel(firstPageItems: [item(1)], nextPage: 2)

        await model.loadMore(client: fixture.client, query: query())
        await model.loadMore(client: fixture.client, query: query())

        #expect(model.items.map(\.id) == [1])
        #expect(model.nextPage == 3)
        #expect(model.errorMessage != nil)
        #expect(!model.isLoadingMore)
        #expect(StreamingCatalogStub.shared.requests.compactMap { $0["page"] } == ["2", "3"])

        await model.retry(client: fixture.client, query: query())

        #expect(model.items.map(\.id) == [1, 2])
        #expect(model.nextPage == nil)
        #expect(model.errorMessage == nil)
        #expect(StreamingCatalogStub.shared.requests.compactMap { $0["page"] } == ["2", "3", "3"])
    }

    @Test("A cancelled page can load again without duplicates or an error")
    func cancellationPreservesNextPage() async throws {
        let requests = AsyncStream<Void>.makeStream()
        defer { requests.continuation.finish() }
        let fixture = StreamingCatalogFixture(
            responses: [2: [.pending, try page(2, totalPages: 2, ids: [2])]],
            requestEvents: requests.continuation
        )
        defer { fixture.session.invalidateAndCancel() }
        let model = StreamingCatalogModel(firstPageItems: [item(1)], nextPage: 2)
        let task = Task { await model.loadMore(client: fixture.client, query: query()) }
        var requestEvents = requests.stream.makeAsyncIterator()
        _ = await requestEvents.next()

        #expect(model.isLoadingMore)
        await model.loadMore(client: fixture.client, query: query())
        #expect(StreamingCatalogStub.shared.requests.count == 1)
        task.cancel()
        await task.value

        #expect(model.items.map(\.id) == [1])
        #expect(model.nextPage == 2)
        #expect(model.errorMessage == nil)
        #expect(!model.isLoadingMore)

        await model.loadMore(client: fixture.client, query: query())

        #expect(model.items.map(\.id) == [1, 2])
        #expect(model.nextPage == nil)
        #expect(StreamingCatalogStub.shared.requests.compactMap { $0["page"] } == ["2", "2"])
    }

    @Test("An interrupted retry resumes the failed page when the catalog reappears", arguments: [false, true])
    func interruptedRetryResumesTheFailedPage(endsWithDuplicate: Bool) async throws {
        let requests = AsyncStream<Void>.makeStream()
        defer { requests.continuation.finish() }
        let recoveredPage = endsWithDuplicate
            ? try page(2, totalPages: 2, ids: [1])
            : try page(2, totalPages: 3, ids: [2])
        let fixture = StreamingCatalogFixture(
            responses: [2: [.response(status: 503, data: Data()), .pending, recoveredPage]],
            requestEvents: requests.continuation
        )
        defer { fixture.session.invalidateAndCancel() }
        let model = StreamingCatalogModel(firstPageItems: [item(1)], nextPage: 2)
        var requestEvents = requests.stream.makeAsyncIterator()
        await model.loadMore(client: fixture.client, query: query())
        _ = await requestEvents.next()
        try #require(model.errorMessage != nil)

        let retry = Task { await model.retry(client: fixture.client, query: query()) }
        _ = await requestEvents.next()
        retry.cancel()
        await retry.value
        #expect(model.items.map(\.id) == [1])
        #expect(model.nextPage == 2)

        await model.retry(client: fixture.client, query: query())
        await model.retry(client: fixture.client, query: query())

        #expect(model.items.map(\.id) == (endsWithDuplicate ? [1] : [1, 2]))
        #expect(model.nextPage == (endsWithDuplicate ? nil : 3))
        #expect(model.errorMessage == nil)
        #expect(StreamingCatalogStub.shared.requests.compactMap { $0["page"] } == ["2", "2", "2"])
    }

    private func query(isTV: Bool = false) -> StreamingAvailabilityQuery {
        StreamingAvailabilityQuery(kind: isTV ? .tv : .movie, region: "BR", providerID: 8, today: "2026-11-23")
    }

    private func item(_ id: Int) -> MediaItem {
        MediaItem(id: id, title: "Title \(id)", overview: "", posterPath: nil, backdropPath: nil,
                  voteAverage: 8, releaseDate: nil, mediaType: .movie)
    }

    private func page(_ number: Int, totalPages: Int, ids: [Int], isTV: Bool = false) throws -> StreamingCatalogResponse {
        let titleKey = isTV ? "name" : "title"
        let data = try JSONSerialization.data(withJSONObject: [
            "page": number,
            "results": ids.map { ["id": $0, titleKey: "Title \($0)"] },
            "total_pages": totalPages,
            "total_results": totalPages * 20
        ])
        return .response(status: 200, data: data)
    }
}

private struct StreamingCatalogFixture {
    let client: TMDBClient
    let session: URLSession

    init(responses: [Int: [StreamingCatalogResponse]], requestEvents: AsyncStream<Void>.Continuation? = nil) {
        StreamingCatalogStub.shared.install(responses: responses, requestEvents: requestEvents)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StreamingCatalogURLProtocol.self]
        session = URLSession(configuration: configuration)
        client = TMDBClient(configuration: TMDBConfiguration(apiKey: "streaming-catalog-test-key"), session: session)
    }
}

private enum StreamingCatalogResponse: Sendable {
    case response(status: Int, data: Data)
    case pending
}

private final class StreamingCatalogStub: @unchecked Sendable {
    static let shared = StreamingCatalogStub()

    private let lock = NSLock()
    private var recordedRequests: [URLComponents] = []
    private var responses: [Int: [StreamingCatalogResponse]] = [:]
    private var requestEvents: AsyncStream<Void>.Continuation?

    var requests: [URLComponents] { lock.withLock { recordedRequests } }

    func install(responses: [Int: [StreamingCatalogResponse]], requestEvents: AsyncStream<Void>.Continuation?) {
        lock.withLock {
            recordedRequests = []
            self.responses = responses
            self.requestEvents = requestEvents
        }
    }

    func response(for request: URLComponents) -> StreamingCatalogResponse? {
        lock.withLock {
            recordedRequests.append(request)
            requestEvents?.yield()
            guard let page = request["page"].flatMap(Int.init), responses[page]?.isEmpty == false else { return nil }
            return responses[page]?.removeFirst()
        }
    }
}

private extension URLComponents {
    subscript(parameter: String) -> String? { queryItems?.first { $0.name == parameter }?.value }
}

private final class StreamingCatalogURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let stub = StreamingCatalogStub.shared.response(for: components) else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }
        guard case let .response(status, data) = stub,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
