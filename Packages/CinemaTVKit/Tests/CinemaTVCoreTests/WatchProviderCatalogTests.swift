import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct WatchProviderCatalogTests {
    @Test func ordersEveryReturnedProviderByTheRequestedRegionThenGlobalPriority() throws {
        let json = """
        {"results":[
          {"provider_id":119,"provider_name":"Prime Video","logo_path":"/prime.jpg","display_priority":0,"display_priorities":{"US":0,"BR":3}},
          {"provider_id":400,"provider_name":"Criterion","logo_path":null},
          {"provider_id":337,"provider_name":"Disney Plus","logo_path":"/disney.jpg","display_priority":99,"display_priorities":{"BR":1}},
          {"provider_id":11,"provider_name":"MUBI","logo_path":"/mubi.jpg","display_priority":4,"display_priorities":{"US":2}},
          {"provider_id":8,"provider_name":"Netflix","logo_path":"/netflix.jpg","display_priority":500,"display_priorities":{"BR":0}}
        ]}
        """

        let catalog = try JSONDecoder.tmdb.decode(
            WatchProviderCatalogResponse.self,
            from: Data(json.utf8)
        )

        let providers = catalog.providers(for: "BR")
        #expect(providers.map(\.providerId) == [8, 337, 119, 11, 400])
        #expect(providers.map(\.providerName) == ["Netflix", "Disney Plus", "Prime Video", "MUBI", "Criterion"])
        #expect(catalog.providers(for: "US").map(\.providerId) == [119, 11, 337, 8, 400])
    }

    @Test func deduplicatesProviderIDsAfterSortingByEffectivePriority() throws {
        let json = """
        {"results":[
          {"provider_id":8,"provider_name":"Netflix Old","logo_path":"/old.jpg","display_priority":1,"display_priorities":{"BR":9}},
          {"provider_id":20,"provider_name":"Other","logo_path":"/other.jpg","display_priority":2,"display_priorities":{"BR":2}},
          {"provider_id":8,"provider_name":"Netflix","logo_path":"/new.jpg","display_priority":50,"display_priorities":{"BR":1}}
        ]}
        """

        let catalog = try JSONDecoder.tmdb.decode(
            WatchProviderCatalogResponse.self,
            from: Data(json.utf8)
        )

        let providers = catalog.providers(for: "BR")
        #expect(providers.map(\.providerId) == [8, 20])
        #expect(providers.first?.logoPath == "/new.jpg")
    }

    @Test func breaksEqualPriorityTiesByNameThenID() throws {
        let json = """
        {"results":[
          {"provider_id":1,"provider_name":"Hulu","display_priority":2},
          {"provider_id":3,"provider_name":"apple","display_priority":2},
          {"provider_id":2,"provider_name":"Apple","display_priority":2}
        ]}
        """

        let catalog = try JSONDecoder.tmdb.decode(
            WatchProviderCatalogResponse.self,
            from: Data(json.utf8)
        )

        #expect(catalog.providers(for: "BR").map(\.providerId) == [2, 3, 1])
    }
}

private extension JSONDecoder {
    static var tmdb: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
