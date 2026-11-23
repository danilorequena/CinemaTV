import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct StreamingServicePreferencesTests {
    @Test func savesAndClearsSelectionsIndependentlyByRegion() {
        var preferences = StreamingServicePreferences(data: Data())
        preferences.setProviderIDs([8, 337], for: "br")
        preferences.setProviderIDs([9], for: "US")

        var restored = StreamingServicePreferences(data: preferences.data)
        #expect(restored.providerIDs(for: "BR") == [8, 337])
        #expect(restored.providerIDs(for: "us") == [9])
        #expect(restored.providerIDs(for: "FR").isEmpty)

        restored.setProviderIDs([], for: "BR")
        let afterClearing = StreamingServicePreferences(data: restored.data)
        #expect(afterClearing.providerIDs(for: "BR").isEmpty)
        #expect(afterClearing.providerIDs(for: "US") == [9])
    }

    @Test func unreadablePreferencesStartWithNoSelections() {
        let preferences = StreamingServicePreferences(data: Data("invalid JSON".utf8))

        #expect(preferences.providerIDs(for: "BR").isEmpty)
    }

    @Test func preservesRegionalCatalogOrderAndIncludesEveryPreferredProvider() {
        let catalog = (1...16).reversed().map(provider)
        var preferences = StreamingServicePreferences(data: Data())
        preferences.setProviderIDs(Set(2...13).union([500]), for: "BR")

        let services = preferences.groupedProviders(catalog, for: "BR")
        #expect(services.preferred.map(\.id) == [13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2])
        #expect(services.other.map(\.id) == [16, 15, 14, 1])
    }

    @Test func leavesTheFullCatalogAvailableWhenSavedProvidersAreMissing() {
        let catalog = [8, 16, 2].map(provider)
        var preferences = StreamingServicePreferences(data: Data())
        preferences.setProviderIDs([500], for: "BR")

        let services = preferences.groupedProviders(catalog, for: "BR")
        #expect(services.preferred.isEmpty)
        #expect(services.other.map(\.id) == [8, 16, 2])
    }

    @Test func combinesMovieAndTVCatalogsByProviderIDAndRegionalPriority() throws {
        let movies = try catalog("""
            {"results":[
              {"provider_id":8,"provider_name":"Netflix","display_priorities":{"BR":5}},
              {"provider_id":11,"provider_name":"MUBI","display_priorities":{"BR":2}}
            ]}
            """)
        let shows = try catalog("""
            {"results":[
              {"provider_id":8,"provider_name":"Netflix","logo_path":"/tv.jpg","display_priorities":{"BR":0}},
              {"provider_id":337,"provider_name":"Disney+","display_priorities":{"BR":1}}
            ]}
            """)

        let services = movies.providers(for: "BR", including: shows)
        #expect(services.map(\.id) == [8, 337, 11])
        #expect(services.first?.logoPath == "/tv.jpg")
    }

    private func provider(_ id: Int) -> WatchProvider {
        WatchProvider(providerId: id, providerName: "Service \(id)", logoPath: nil)
    }

    private func catalog(_ json: String) throws -> WatchProviderCatalogResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WatchProviderCatalogResponse.self, from: Data(json.utf8))
    }
}
