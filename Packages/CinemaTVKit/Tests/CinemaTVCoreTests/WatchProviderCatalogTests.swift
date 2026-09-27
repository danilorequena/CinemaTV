import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct WatchProviderCatalogTests {
    @Test func decodesProviderIDsAndNamesForRegionSelection() throws {
        let json = """
        {"results":[
          {"provider_id":8,"provider_name":"Netflix","logo_path":"/netflix.jpg","display_priority":1},
          {"provider_id":337,"provider_name":"Disney Plus","logo_path":"/disney.jpg","display_priority":2}
        ]}
        """

        let catalog = try JSONDecoder.tmdb.decode(
            WatchProviderCatalogResponse.self,
            from: Data(json.utf8)
        )

        #expect(catalog.results.map(\.providerId) == [8, 337])
        #expect(catalog.results.map(\.providerName) == ["Netflix", "Disney Plus"])
    }
}

private extension JSONDecoder {
    static var tmdb: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
