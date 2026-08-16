//
//  CinemaTVTests.swift
//  CinemaTVTests
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation
import Testing
@testable import CinemaTV

// MARK: - DeepLink

@Suite("DeepLink parsing")
struct DeepLinkTests {
    @Test("cinematv://movie/603 parses to .movie(id: 603)")
    func parsesMovieLink() throws {
        let url = try #require(URL(string: "cinematv://movie/603"))
        #expect(DeepLink(url: url) == .movie(id: 603))
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
            "cinematv://movie/notanumber" // movie with non-numeric id
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

    @Test("open(.movie) selects discover tab and pushes onto discoverPath")
    func openMovieSelectsDiscoverTabAndPushes() {
        let router = AppRouter()
        router.selectedTab = .search
        let initialCount = router.discoverPath.count

        router.open(.movie(id: 603))

        #expect(router.selectedTab == .discover)
        #expect(router.discoverPath.count == initialCount + 1)
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
