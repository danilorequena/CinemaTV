import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import CinemaTVCore

@Suite struct LifetimeMetadataCacheTests {
    @Test func persistsMovieAndShowDetailsForOfflineReuse() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "lifetime-metadata-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let first = LifetimeMetadataCache(fileURL: url)
        await first.putMovie(.init(runtimeMinutes: 142, genres: ["Drama"], releaseYear: 1999), id: 1, locale: "pt-BR")
        await first.putShow(.init(genres: ["Comedy"], firstAirYear: 2010), id: 2, locale: "pt-BR")
        await first.putSeason(.init(runtimesByEpisode: [1: 44, 2: 52]), showID: 2, seasonNumber: 1, locale: "pt-BR")
        await first.flush()

        let reopened = LifetimeMetadataCache(fileURL: url)
        #expect(await reopened.movie(id: 1, locale: "pt-BR")?.runtimeMinutes == 142)
        #expect(await reopened.show(id: 2, locale: "pt-BR")?.genres == ["Comedy"])
        #expect(await reopened.season(showID: 2, seasonNumber: 1, locale: "pt-BR")?.runtimesByEpisode[2] == 52)
        #expect(await reopened.season(showID: 2, seasonNumber: 1, locale: "en-US") == nil)
        #expect(await reopened.movie(id: 1, locale: "en-US") == nil)
        let offlineClient = TMDBClient(configuration: TMDBConfiguration(apiKey: ""))
        let offlineValue = try await reopened.loadMovie(id: 1, locale: "pt-BR", client: offlineClient)
        #expect(offlineValue.runtimeMinutes == 142)
        let offlineSeason = try await reopened.loadSeason(showID: 2, seasonNumber: 1, locale: "pt-BR", client: offlineClient)
        #expect(offlineSeason.runtimesByEpisode[1] == 44)
    }

    @Test func fetchesOnlyKnownEpisodeRuntimesFromSeasonDetails() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "lifetime-season-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LifetimeSeasonURLProtocol.self]
        let client = TMDBClient(configuration: TMDBConfiguration(apiKey: "test"), session: URLSession(configuration: configuration))
        let cache = LifetimeMetadataCache(fileURL: url)

        let season = try await cache.loadSeason(showID: 123, seasonNumber: 2, locale: "pt-BR", client: client)
        #expect(season.runtimesByEpisode == [1: 48])
        await cache.flush()
        let reopened = LifetimeMetadataCache(fileURL: url)
        #expect(await reopened.season(showID: 123, seasonNumber: 2, locale: "pt-BR") == season)
    }

    @Test func keepsPreSeasonCacheEntriesWhenOpeningOlderCacheFile() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "lifetime-legacy-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(#"{"movies":{"pt-BR:1":{"runtimeMinutes":110,"genres":[],"releaseYear":null}},"shows":{}}"#.utf8).write(to: url)
        let cache = LifetimeMetadataCache(fileURL: url)
        #expect(await cache.movie(id: 1, locale: "pt-BR")?.runtimeMinutes == 110)
    }
}

private final class LifetimeSeasonURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let body = #"{"_id":"season-id","name":"Season 2","season_number":2,"episodes":[{"id":1,"name":"One","episode_number":1,"runtime":48},{"id":2,"name":"Two","episode_number":2,"runtime":null},{"id":3,"name":"Three","episode_number":3,"runtime":0}]}"#
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
