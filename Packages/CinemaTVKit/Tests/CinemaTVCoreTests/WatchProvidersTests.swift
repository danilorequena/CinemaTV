//
//  WatchProvidersTests.swift
//  CinemaTVKit
//

import Foundation
import Testing
@testable import CinemaTVCore

@Suite(.serialized)
struct WatchProvidersTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    @Test func missingSelectedRegionDoesNotShowAnotherCountrysServices() throws {
        let previous = TMDBRegion.store.string(forKey: TMDBRegion.overrideKey)
        defer { TMDBRegion.store.set(previous, forKey: TMDBRegion.overrideKey) }
        TMDBRegion.store.set("BR", forKey: TMDBRegion.overrideKey)

        let response = try decoder.decode(WatchProvidersResponse.self, from: Data("""
        {"id":603,"results":{"US":{"link":"https://www.themoviedb.org/movie/603/watch?locale=US","flatrate":[{"provider_id":8,"provider_name":"Netflix","logo_path":"/netflix.png"}]}}}
        """.utf8))

        #expect(response.currentRegion == nil)
    }

    @Test func decodesFreeAndAdSupportedOffers() throws {
        let response = try decoder.decode(WatchProvidersResponse.self, from: Data("""
        {"id":603,"results":{"BR":{"link":"https://www.themoviedb.org/movie/603/watch?locale=BR","free":[{"provider_id":10,"provider_name":"Free service","logo_path":null}],"ads":[{"provider_id":11,"provider_name":"Ad service","logo_path":null}]}}}
        """.utf8))
        let providers = try #require(response.results["BR"])

        #expect(providers.free?.map(\.providerName) == ["Free service"])
        #expect(providers.ads?.map(\.providerName) == ["Ad service"])
        #expect(providers.hasOffers)
    }

    @Test func watchPageURLRejectsNonTMDBLinks() throws {
        let response = try decoder.decode(WatchProvidersResponse.self, from: Data("""
        {"id":603,"results":{"BR":{"link":"https://www.themoviedb.org/movie/603/watch?locale=BR"},"US":{"link":"https://example.com/movie/603"},"PT":{"link":"http://www.themoviedb.org/movie/603/watch"}}}
        """.utf8))

        #expect(response.results["BR"]?.watchPageURL?.absoluteString == "https://www.themoviedb.org/movie/603/watch?locale=BR")
        #expect(response.results["US"]?.watchPageURL == nil)
        #expect(response.results["PT"]?.watchPageURL == nil)
    }

    @Test func emptyProviderListsAreNotShownAsAvailable() throws {
        let response = try decoder.decode(WatchProvidersResponse.self, from: Data("""
        {"id":603,"results":{"BR":{"link":"https://www.themoviedb.org/movie/603/watch?locale=BR","flatrate":[],"free":[],"ads":[],"rent":[],"buy":[]}}}
        """.utf8))

        #expect(response.results["BR"]?.hasOffers == false)
    }
}
