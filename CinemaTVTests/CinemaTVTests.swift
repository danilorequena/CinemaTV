//
//  CinemaTVTests.swift
//  CinemaTVTests
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation
import Testing
import CinemaTVCore
@testable import CinemaTV

// MARK: - DeepLink

@Suite("DeepLink parsing")
struct DeepLinkTests {
    @Test("cinematv://movie/603 parses to .movie(id: 603)")
    func parsesMovieLink() throws {
        let url = try #require(URL(string: "cinematv://movie/603"))
        #expect(DeepLink(url: url) == .movie(id: 603))
    }

    @Test("cinematv://tvshow/1399 parses to .tvShow(id: 1399)")
    func parsesTVShowLink() throws {
        let url = try #require(URL(string: "cinematv://tvshow/1399"))
        #expect(DeepLink(url: url) == .tvShow(id: 1399))
    }

    @Test("cinematv://watchlist parses to .watchlist")
    func parsesWatchlistLink() throws {
        let url = try #require(URL(string: "cinematv://watchlist"))
        #expect(DeepLink(url: url) == .watchlist)
    }

    @Test("cinematv://search?q=matrix parses to .search(query: \"matrix\")")
    func parsesSearchLinkWithQuery() throws {
        let url = try #require(URL(string: "cinematv://search?q=matrix"))
        #expect(DeepLink(url: url) == .search(query: "matrix"))
    }

    @Test("cinematv://search without query parses to .search(query: nil)")
    func parsesSearchLinkWithoutQuery() throws {
        let url = try #require(URL(string: "cinematv://search"))
        #expect(DeepLink(url: url) == .search(query: nil))
    }

    @Test(
        "Invalid URLs return nil",
        arguments: [
            "https://movie/603",          // wrong scheme
            "cinematv://unknown",         // unknown host
            "cinematv://movie",           // movie without id
            "cinematv://movie/notanumber", // movie with non-numeric id
            "cinematv://tvshow",           // tv show without id
            "cinematv://tvshow/notanumber" // tv show with non-numeric id
        ]
    )
    func invalidURLsReturnNil(urlString: String) throws {
        let url = try #require(URL(string: urlString))
        #expect(DeepLink(url: url) == nil)
    }

    @Test(
        "Round-trip: DeepLink(url: link.url) == link",
        arguments: [
            DeepLink.movie(id: 603),
            DeepLink.tvShow(id: 1399),
            DeepLink.watchlist,
            DeepLink.search(query: "matrix"),
            DeepLink.search(query: nil)
        ]
    )
    func roundTrip(link: DeepLink) {
        #expect(DeepLink(url: link.url) == link)
    }
}

// MARK: - AppRouter

@Suite("AppRouter deep link handling")
@MainActor
struct AppRouterTests {
    @Test("tracking is the default tab")
    func trackingIsDefaultTab() {
        let router = AppRouter()

        #expect(router.selectedTab == .tracking)
    }

    @Test("opening a movie externally preserves the current tab and Discover path")
    func openMoviePreservesCurrentNavigation() async {
        let router = AppRouter()
        router.selectedTab = .search
        router.discoverPath.append(Route.tvShowDetail(id: 1399))
        let initialCount = router.discoverPath.count

        router.open(.movie(id: 603))

        await Task { @MainActor in }.value
        #expect(router.selectedTab == .search)
        #expect(router.discoverPath.count == initialCount)
    }

    @Test("opening a TV show externally preserves the current tab and Discover path")
    func openTVShowPreservesCurrentNavigation() async {
        let router = AppRouter()
        router.selectedTab = .tracking
        router.discoverPath.append(Route.movieDetail(id: 603))
        let initialCount = router.discoverPath.count

        router.open(.tvShow(id: 1399))

        await Task { @MainActor in }.value
        #expect(router.selectedTab == .tracking)
        #expect(router.discoverPath.count == initialCount)
    }

    @Test("a season opened from an external TV show does not navigate the hidden tab")
    func externalSeasonPushLeavesTabPathsUntouched() {
        let router = AppRouter()
        router.open(.tvShow(id: 1399))

        router.push(.season(tvShowID: 1399, seasonNumber: 1, sourceID: nil))

        #expect(router.trackingPath.isEmpty)
        #expect(router.discoverPath.isEmpty)
        #expect(router.searchPath.isEmpty)
        #expect(router.externalMediaPath.count == 1)
    }

    @Test("opening media externally replaces an active import presentation")
    func externalMediaReplacesImport() {
        let router = AppRouter()
        router.presentLibraryImport(text: "Dune")

        router.open(.movie(id: 603))

        guard case .some(.externalMedia(.movie(id: 603))) = router.presentation?.content else {
            Issue.record("The movie should replace the import presentation")
            return
        }
    }

    @Test("starting import replaces an external media presentation")
    func importReplacesExternalMedia() {
        let router = AppRouter()
        router.open(.movie(id: 603))

        router.presentLibraryImport(text: "Dune")

        guard case .some(.libraryImport(let request)) = router.presentation?.content else {
            Issue.record("The import should replace the movie presentation")
            return
        }
        #expect(request.text == "Dune")
    }

    @Test("open(.watchlist) selects tracking tab and resets trackingPath")
    func openWatchlistSelectsTrackingTabAndResetsPath() {
        let router = AppRouter()
        router.trackingPath.append("something")

        router.open(.watchlist)

        #expect(router.selectedTab == .tracking)
        #expect(router.trackingPath.isEmpty)
    }

    @Test("open(.search(query:)) selects search tab and sets searchQuery")
    func openSearchWithQuerySetsQuery() {
        let router = AppRouter()

        router.open(.search(query: "matrix"))

        #expect(router.selectedTab == .search)
        #expect(router.searchQuery == "matrix")
        #expect(router.searchPath.isEmpty)
    }

    @Test("open(.search(query: nil)) keeps existing searchQuery")
    func openSearchWithNilQueryKeepsExistingQuery() {
        let router = AppRouter()
        router.searchQuery = "blade runner"

        router.open(.search(query: nil))

        #expect(router.selectedTab == .search)
        #expect(router.searchQuery == "blade runner")
    }
}

// MARK: - Visual Intelligence

@Suite("VisualMediaResult mapping")
struct VisualMediaQueryTests {
    private func item(id: Int, type: MediaItem.MediaType, title: String = "Item") -> MediaItem {
        MediaItem(
            id: id,
            title: title,
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: nil,
            mediaType: type
        )
    }

    @Test("Person results are filtered out")
    func filtersPersons() {
        let results = VisualMediaResult.results(from: [
            item(id: 1, type: .person),
            item(id: 2, type: .movie),
            item(id: 3, type: .person)
        ])

        #expect(results.count == 1)
    }

    @Test("Movies and TV shows map to their union cases")
    func mapsMediaTypesToCases() throws {
        let results = VisualMediaResult.results(from: [
            item(id: 603, type: .movie, title: "The Matrix"),
            item(id: 1399, type: .tvShow, title: "Game of Thrones")
        ])

        try #require(results.count == 2)
        guard case .movie(let movie) = results[0] else {
            Issue.record("Expected .movie as first result")
            return
        }
        guard case .tvShow(let show) = results[1] else {
            Issue.record("Expected .tvShow as second result")
            return
        }
        #expect(movie.id == 603)
        #expect(show.id == 1399)
    }

    @Test("Duplicates of the same type and id are removed")
    func deduplicatesSameTypeAndID() {
        let results = VisualMediaResult.results(from: [
            item(id: 603, type: .movie),
            item(id: 603, type: .movie),
            item(id: 1399, type: .tvShow),
            item(id: 1399, type: .tvShow)
        ])

        #expect(results.count == 2)
    }

    @Test("A movie and a TV show sharing the same numeric id both survive")
    func sameIDAcrossTypesDoesNotCollide() {
        let results = VisualMediaResult.results(from: [
            item(id: 42, type: .movie),
            item(id: 42, type: .tvShow)
        ])

        #expect(results.count == 2)
    }

    @Test("Results are capped at 10")
    func capsAtTen() {
        let items = (1...25).map { item(id: $0, type: $0.isMultiple(of: 2) ? .movie : .tvShow) }

        #expect(VisualMediaResult.results(from: items).count == 10)
    }

    @Test("Empty input produces empty output")
    func emptyInput() {
        #expect(VisualMediaResult.results(from: []).isEmpty)
    }
}

@Suite("Boxes navigation")
@MainActor
struct BoxesNavigationTests {
    @Test func sharedEditionDeepLinkRoundTrips() {
        let link = DeepLink.box(editionID: UUID())
        #expect(DeepLink(url: link.url) == link)
        #expect(DeepLink(url: DeepLink.boxes.url) == .boxes)
    }

    @Test(arguments: [
        "cinematv://box/not-a-uuid",
        "cinematv://box/5c085737-b280-4b09-9bbf-9414c608c045/extra",
        "https://untrusted.example/boxes/5c085737-b280-4b09-9bbf-9414c608c045"
    ])
    func invalidBoxLinksAreRejected(_ raw: String) throws {
        #expect(DeepLink(url: try #require(URL(string: raw))) == nil)
    }

    @Test func receivingABoxSelectsLibraryAndPreservesOtherTabs() async {
        let router = AppRouter()
        router.selectedTab = .search
        router.searchQuery = "Interstellar"
        router.discoverPath.append(Route.movieDetail(id: 157336))
        router.open(.box(editionID: UUID()))
        #expect(router.selectedTab == .tracking)
        // Navigation appends on the next main-actor turn after switching tabs.
        await Task { @MainActor in }.value
        #expect(router.trackingPath.count == 1)
        #expect(router.discoverPath.count == 1)
        #expect(router.searchQuery == "Interstellar")
    }

    @Test func openingShelfOnActiveLibraryPushesImmediately() {
        let router = AppRouter()
        router.open(.boxes)
        #expect(router.trackingPath.count == 1)
    }
}
