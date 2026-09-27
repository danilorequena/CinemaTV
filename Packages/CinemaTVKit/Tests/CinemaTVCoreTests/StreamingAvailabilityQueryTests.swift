import Testing
@testable import CinemaTVCore

@Suite struct StreamingAvailabilityQueryTests {
    @Test func movieQueryFindsRecentSubscriptionReleasesInSelectedCountry() {
        let query = StreamingAvailabilityQuery(
            kind: .movie,
            region: "BR",
            providerID: 8,
            today: "2026-09-27"
        )

        #expect(query.catalogEndpoint == .movieWatchProviderCatalog)
        #expect(query.catalogParameters == ["watch_region": "BR"])
        #expect(query.discoverEndpoint == .discoverMovies)
        #expect(query.parameters == [
            "watch_region": "BR",
            "with_watch_providers": "8",
            "with_watch_monetization_types": "flatrate",
            "sort_by": "primary_release_date.desc",
            "primary_release_date.lte": "2026-09-27"
        ])
    }

    @Test func tvQueryUsesFirstSeriesPremiereRatherThanEpisodeAirDate() {
        let query = StreamingAvailabilityQuery(
            kind: .tv,
            region: "US",
            providerID: 337,
            today: "2026-09-27"
        )

        #expect(query.catalogEndpoint == .tvWatchProviderCatalog)
        #expect(query.catalogParameters == ["watch_region": "US"])
        #expect(query.discoverEndpoint == .discoverTVShows)
        #expect(query.parameters == [
            "watch_region": "US",
            "with_watch_providers": "337",
            "with_watch_monetization_types": "flatrate",
            "sort_by": "first_air_date.desc",
            "first_air_date.lte": "2026-09-27"
        ])
    }
}
