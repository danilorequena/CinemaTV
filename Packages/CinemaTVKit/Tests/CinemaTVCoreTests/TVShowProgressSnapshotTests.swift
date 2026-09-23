import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct TVShowProgressSnapshotTests {
    @Test func directProgressExcludesSpecialsAndFallsBackToSeasonTotals() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = TVShowTrackingStore(container: container)
        let show = TVShowWatchingModel(id: 7, name: "Show")
        let regular = SeasonSD(episodeCount: 3, seasonNumber: 1, tvShow: show)
        let specials = SeasonSD(episodeCount: 20, seasonNumber: 0, tvShow: show)
        regular.episodes = [EpisodeSD(episodeNumber: 1, season: regular)]
        specials.episodes = [
            EpisodeSD(episodeNumber: 1, season: specials),
            EpisodeSD(episodeNumber: 2, season: specials)
        ]
        show.seasons = [specials, regular]

        #expect(store.showProgress(of: show) == WatchProgress(watched: 1, total: 3))
    }

    @Test func directProgressPrefersCachedShowTotal() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = TVShowTrackingStore(container: container)
        let show = TVShowWatchingModel(id: 7, name: "Show", totalEpisodes: 12)
        let season = SeasonSD(episodeCount: 3, seasonNumber: 1, tvShow: show)
        season.episodes = [
            EpisodeSD(episodeNumber: 1, season: season),
            EpisodeSD(episodeNumber: 2, season: season)
        ]
        show.seasons = [season]

        #expect(store.showProgress(of: show) == WatchProgress(watched: 2, total: 12))
    }

    @Test func directProgressIncludesPendingRelationshipMutations() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = TVShowTrackingStore(container: container)
        let show = TVShowWatchingModel(id: 7, name: "Show", totalEpisodes: 2)
        let season = SeasonSD(episodeCount: 2, seasonNumber: 1, tvShow: show)
        show.seasons = [season]
        container.mainContext.insert(show)

        #expect(store.showProgress(of: show) == WatchProgress(watched: 0, total: 2))

        container.mainContext.insert(EpisodeSD(episodeNumber: 1, season: season))

        #expect(store.showProgress(of: show) == WatchProgress(watched: 1, total: 2))
    }
}
