//
//  CinemaTVUITests.swift
//  CinemaTVUITests
//
//  Created by Danilo Requena on 07/11/21.
//

import XCTest

class CinemaTVUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

final class LifetimeUITests: XCTestCase {
    @MainActor
    func testPortugueseLifetimeTabIsLocalized() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launch()

        let tab = app.tabBars.buttons["Sua História"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(app.staticTexts["Sua história"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLifetimeTabHasAnEmptyStateAndOptionalBirthday() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let lifetimeTab = app.tabBars.buttons["Lifetime"]
        XCTAssertTrue(lifetimeTab.waitForExistence(timeout: 10))
        lifetimeTab.tap()
        XCTAssertTrue(app.staticTexts["Your Story"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Track a movie or episode to start your story."].exists)
        app.buttons["lifetime.birthday.edit"].tap()
        XCTAssertTrue(app.datePickers["lifetime.birthday.picker"].waitForExistence(timeout: 5))
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["The comparison will appear when runtime data is available."].waitForExistence(timeout: 5))
        app.buttons["lifetime.birthday.edit"].tap()
        app.buttons["lifetime.birthday.remove"].tap()
        XCTAssertFalse(app.staticTexts["lifetime.lifePercentage"].exists)
    }

    @MainActor
    func testTrackedHistoryShowsChartsAndShareCard() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["CINEMATV_UI_TEST_SEED_LIFETIME"] = "1"
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.tabBars.buttons["Lifetime"].tap()
        XCTAssertTrue(app.staticTexts["lifetime.duration"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your timeline"].exists)
        XCTAssertTrue(app.staticTexts["Shows that stayed with you"].exists)
        let dashboard = XCTAttachment(screenshot: app.screenshot())
        dashboard.name = "Lifetime dashboard"
        dashboard.lifetime = .keepAlways
        add(dashboard)
        let percentage = app.staticTexts["lifetime.lifePercentage"]
        for _ in 0..<5 where !percentage.exists { app.swipeUp() }
        XCTAssertTrue(percentage.exists)
        app.buttons["lifetime.share"].tap()
        XCTAssertTrue(app.buttons["lifetime.share.confirm"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Lifetime share preview"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

final class BoxesUITests: XCTestCase {
    @MainActor
    func testToolbarOpensBoxesInsteadOfSettings() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let boxesButton = app.buttons["Boxes"]
        XCTAssertTrue(boxesButton.waitForExistence(timeout: 10))
        boxesButton.tap()
        XCTAssertTrue(app.navigationBars["My Boxes"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCreateReopenEditAndExportPersonalBox() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let shelf = app.buttons["boxes.libraryEntry"]
        XCTAssertTrue(shelf.waitForExistence(timeout: 10))
        shelf.tap()
        app.buttons["Create a Box"].firstMatch.tap()
        let title = app.descendants(matching: .any)["boxes.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("A quiet evening")
        app.buttons["Next"].tap()
        app.buttons["boxes.addContent"].tap()
        app.buttons["Write My Impression"].tap()
        let note = app.descendants(matching: .any)["A scene, a feeling, a memory…"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.typeText("The final scene stayed with me.")
        app.buttons["Add"].tap()
        app.buttons["Next"].tap()
        app.buttons["Save Box"].tap()
        XCTAssertTrue(app.staticTexts["A quiet evening"].firstMatch.waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        app.buttons["boxes.libraryEntry"].tap()
        app.staticTexts["A quiet evening"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["The final scene stayed with me."].waitForExistence(timeout: 5))
        let detail = XCTAttachment(screenshot: app.screenshot())
        detail.name = "Boxes - persistent personal edition"
        detail.lifetime = .keepAlways
        add(detail)

        app.buttons["Edit Box"].firstMatch.tap()
        app.segmentedControls.buttons["Contents"].tap()
        app.staticTexts["My Impression"].firstMatch.tap()
        let edited = app.descendants(matching: .any)["boxes.reviewText"]
        XCTAssertTrue(edited.waitForExistence(timeout: 5))
        edited.tap()
        edited.typeText(" A new thought.")
        app.buttons["Save"].tap()
        app.segmentedControls.buttons["Review Box"].tap()
        app.buttons["Save Box"].tap()
        app.buttons["Share Box"].tap()
        app.buttons["Share Cover Only"].tap()
        XCTAssertTrue(app.cells["Copy"].waitForExistence(timeout: 10))
        let share = XCTAttachment(screenshot: app.screenshot())
        share.name = "Boxes - cover share sheet"
        share.lifetime = .keepAlways
        add(share)
    }
}

final class LibraryEntryUITests: XCTestCase {
    @MainActor
    func testImportAndICloudDiagnosticsOpenFromLibrary() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let importButton = app.buttons["Import"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 10))
        importButton.tap()
        XCTAssertTrue(app.navigationBars["Import"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Review Titles"].isEnabled)
        app.buttons["Cancel"].tap()

        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["iCloud Sync"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        app.buttons["Discover"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Discover"].waitForExistence(timeout: 5))
    }
}

final class ExternalMediaNavigationUITests: XCTestCase {
    @MainActor
    func testColdOpenMovieCanCloseToLibrary() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        if app.state != .notRunning { app.terminate() }
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

        app.open(URL(string: "cinematv://movie/603")!)
        XCTAssertTrue(app.buttons["Mark as Watched"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Discover"].exists)
    }

    @MainActor
    func testExternalMovieReplacesImportWithoutLosingLibrary() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Import"].tap()
        XCTAssertTrue(app.navigationBars["Import"].waitForExistence(timeout: 5))
        app.open(URL(string: "cinematv://movie/603")!)
        XCTAssertTrue(app.buttons["Mark as Watched"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Discover"].exists)
    }

    @MainActor
    func testSecondExternalResultReplacesFirstAndClosesToLibrary() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 10))
        app.open(URL(string: "cinematv://movie/603")!)
        XCTAssertTrue(app.buttons["Mark as Watched"].waitForExistence(timeout: 10))
        app.open(URL(string: "cinematv://tvshow/1399")!)
        XCTAssertTrue(app.buttons["Follow"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOpeningMovieFromOutsideReturnsToPreviousLibraryScreen() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 10))
        app.open(URL(string: "cinematv://movie/603")!)
        XCTAssertTrue(app.buttons["Mark as Watched"].waitForExistence(timeout: 10))

        let close = app.buttons["Close"]
        if close.exists {
            close.tap()
        } else {
            app.navigationBars.buttons.firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOpeningTVShowFromOutsideReturnsToPreviousLibraryScreen() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 10))
        app.open(URL(string: "cinematv://tvshow/1399")!)
        XCTAssertTrue(app.buttons["Follow"].waitForExistence(timeout: 10))

        let close = app.buttons["Close"]
        if close.exists {
            close.tap()
        } else {
            app.navigationBars.buttons.firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["Boxes"].waitForExistence(timeout: 5))
    }
}

final class StreamingDiscoveryUITests: XCTestCase {
    @MainActor
    func testSeeMoreLoadsAdditionalMoviesFromTheSameService() {
        assertPaginatedCatalog(feedID: "discover.movies.feed", providerID: 9, providerName: "Prime Video")
    }

    @MainActor
    func testSeeMoreLoadsAdditionalSeriesFromTheSameService() {
        assertPaginatedCatalog(feedID: "discover.tv.feed", providerID: 337, providerName: "Disney Plus")
    }

    @MainActor
    private func assertPaginatedCatalog(feedID: String, providerID: Int, providerName: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["CINEMATV_UI_TEST_STREAMING_FIXTURES"] = "pagination"
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.tabBars.buttons["Discover"].tap()
        if feedID == "discover.tv.feed" {
            app.segmentedControls.buttons["TV Shows"].tap()
        }

        let feed = app.scrollViews[feedID]
        XCTAssertTrue(feed.waitForExistence(timeout: 15))
        let seeMore = app.descendants(matching: .any)["streaming.seeMore.\(providerID)"]
        for _ in 0..<8 where !seeMore.isHittable {
            feed.swipeUp()
        }
        XCTAssertTrue(seeMore.isHittable)
        seeMore.tap()

        XCTAssertTrue(app.navigationBars[providerName].waitForExistence(timeout: 10))
        let catalog = app.scrollViews["streaming.catalog"]
        XCTAssertTrue(catalog.waitForExistence(timeout: 10))
        let firstTitle = app.descendants(matching: .any)["streaming.catalog.item.\(providerID * 100 + 1)"]
        XCTAssertTrue(firstTitle.exists)
        let nextPageTitle = app.descendants(matching: .any)["streaming.catalog.item.\(providerID * 100 + 21)"]
        for _ in 0..<8 where !nextPageTitle.isHittable {
            catalog.swipeUp()
        }
        XCTAssertTrue(nextPageTitle.isHittable)
    }

    @MainActor
    func testMoviesShowRegionalStreamingReleases() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Discover"].firstMatch.tap()
        assertStreamingResults(in: app, feedID: "discover.movies.feed")
    }

    @MainActor
    func testTVShowsShowRegionalStreamingReleases() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Discover"].firstMatch.tap()
        app.segmentedControls.buttons["TV Shows"].tap()
        assertStreamingResults(in: app, feedID: "discover.tv.feed")
    }

    @MainActor
    func testCanRevealMoreRegionalServices() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Discover"].firstMatch.tap()
        let feed = app.scrollViews["discover.movies.feed"]
        XCTAssertTrue(feed.waitForExistence(timeout: 30))

        let showMore = app.buttons["streaming.showMore"]
        for _ in 0..<18 where !showMore.isHittable {
            feed.swipeUp()
        }
        XCTAssertTrue(showMore.isHittable)
        let before = try XCTUnwrap(showMore.value as? String)
        showMore.tap()
        let changed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", before),
            object: showMore
        )
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
    }

    @MainActor
    func testMovieDetailShowsWhereToWatchAndAttribution() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.open(URL(string: "cinematv://movie/603")!)

        XCTAssertTrue(app.staticTexts["The Matrix"].waitForExistence(timeout: 30))
        let heading = app.staticTexts["Where to Watch"]
        for _ in 0..<8 where !heading.exists {
            app.swipeUp()
        }
        XCTAssertTrue(heading.waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Availability data provided by JustWatch"].exists)
    }

    @MainActor
    private func assertStreamingResults(in app: XCUIApplication, feedID: String) {
        let feed = app.scrollViews[feedID]
        XCTAssertTrue(feed.waitForExistence(timeout: 30))

        let streaming = app.staticTexts["Newest titles to stream"]
        for _ in 0..<8 where !streaming.exists {
            feed.swipeUp()
        }
        XCTAssertTrue(streaming.waitForExistence(timeout: 10))

        let resultsPrefix = "streaming.results."
        let results = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", resultsPrefix))
            .firstMatch
        if !results.waitForExistence(timeout: 10) {
            for _ in 0..<6 where !results.exists {
                feed.swipeUp()
            }
        }
        XCTAssertTrue(results.waitForExistence(timeout: 30))
        let providerID = String(results.identifier.dropFirst(resultsPrefix.count))
        XCTAssertTrue(
            app.descendants(matching: .any)["streaming.provider.\(providerID)"]
                .waitForExistence(timeout: 30)
        )
    }
}

final class OnboardingUITests: XCTestCase {
    private static let englishChapters = [
        "Find your next watch",
        "Build your Library",
        "Go beyond the credits",
        "See your Lifetime",
        "Make a Box",
        "CinemaTV at a glance",
        "Make it yours"
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTourShowsAllSevenChaptersAndRemembersCompletion() {
        let app = makeApp()
        app.launch()
        assertChapter(Self.englishChapters[0], in: app)
        tap("onboarding.next", in: app)
        assertChapter(Self.englishChapters[1], in: app)
        tap("onboarding.back", in: app)

        advanceToFinalChapter(in: app)
        tap("onboarding.openLibrary", in: app)
        assertLibrary(in: app)

        app.terminate()
        app.launch()
        assertLibrary(in: app)
    }

    @MainActor
    func testSkipPersistsAndSettingsCanReplayTheTour() {
        let app = makeApp()
        app.launch()
        assertChapter(Self.englishChapters[0], in: app)
        tap("onboarding.skip", in: app)
        assertLibrary(in: app)

        app.terminate()
        app.launch()
        assertLibrary(in: app)
        tap("Settings", in: app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        tap("onboarding.review", in: app, scroll: true)

        assertChapter(Self.englishChapters[0], in: app)
        XCTAssertFalse(app.buttons["onboarding.skip"].exists)
        tap("onboarding.close", in: app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        tap("onboarding.review", in: app, scroll: true)
        advanceToFinalChapter(in: app)
        XCTAssertFalse(app.buttons["onboarding.search"].exists)
        XCTAssertFalse(app.buttons["onboarding.import"].exists)
        tap("onboarding.done", in: app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.navigationBars["Settings"].buttons["Done"].tap()
        assertLibrary(in: app)
    }

    @MainActor
    func testFinalSearchActionOpensSearch() {
        let app = makeApp()
        app.launch()
        advanceToFinalChapter(in: app)
        tap("onboarding.search", in: app)

        XCTAssertTrue(app.staticTexts["Trending"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["onboarding.title"].exists)
    }

    @MainActor
    func testFinalImportActionOpensLibraryImport() {
        let app = makeApp()
        app.launch()
        advanceToFinalChapter(in: app)
        tap("onboarding.import", in: app)

        let importBar = app.navigationBars["Import"]
        XCTAssertTrue(importBar.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Review Titles"].isEnabled)
        importBar.buttons["Cancel"].tap()
        assertLibrary(in: app)
    }

    @MainActor
    func testColdDeepLinkDefersTheTourUntilANormalLaunch() throws {
        let app = makeApp()
        if app.state != .notRunning { app.terminate() }
        app.open(try XCTUnwrap(URL(string: "cinematv://watchlist")))
        assertLibrary(in: app)

        app.terminate()
        app.launch()
        openStreamingPicker(in: app)
        app.open(try XCTUnwrap(URL(string: "cinematv://movie/603")))
        XCTAssertTrue(app.navigationBars["My Streaming Services"].waitForNonExistence(timeout: 5))
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["onboarding.title"].exists)
        close.tap()
        assertLibrary(in: app)

        app.terminate()
        app.launch()
        assertChapter(Self.englishChapters[0], in: app)
    }

    @MainActor
    func testPortugueseTourTitleIsLocalized() {
        let app = makeApp(language: "pt-BR", locale: "pt_BR")
        app.launch()

        assertChapter("Encontre o que assistir", in: app)
        tap("onboarding.next", in: app)
        assertChapter("Monte sua Biblioteca", in: app)
    }

    @MainActor
    func testFrenchTourCanAdvanceAtTheLargestAccessibilityTextSize() {
        let app = makeApp(language: "fr", locale: "fr_FR")
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()

        assertChapter("Trouvez quoi regarder", in: app)
        tap("onboarding.next", in: app, scroll: true)
        assertChapter("Créez votre bibliothèque", in: app)
    }

    @MainActor
    func testTourCanSaveStreamingServicesAndCancelUncommittedChanges() {
        let app = makeApp()
        app.launch()
        openStreamingPicker(in: app)

        let netflix = app.buttons["streaming.picker.provider.8"]
        XCTAssertTrue(netflix.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "streaming.picker.provider.8").count, 1)
        XCTAssertTrue(app.buttons["streaming.picker.provider.9"].exists)
        XCTAssertTrue(app.buttons["streaming.picker.provider.337"].exists)
        XCTAssertFalse(netflix.isSelected)
        netflix.tap()
        XCTAssertTrue(netflix.isSelected)
        tap("streaming.picker.save", in: app)
        XCTAssertTrue(app.navigationBars["My Streaming Services"].waitForNonExistence(timeout: 5))

        app.terminate()
        app.launch()
        openStreamingPicker(in: app)
        XCTAssertTrue(netflix.waitForExistence(timeout: 5))
        XCTAssertTrue(netflix.isSelected)
        netflix.tap()
        XCTAssertFalse(netflix.isSelected)
        tap("streaming.picker.cancel", in: app)
        XCTAssertTrue(app.navigationBars["My Streaming Services"].waitForNonExistence(timeout: 5))

        openStreamingPicker(in: app)
        XCTAssertTrue(netflix.waitForExistence(timeout: 5))
        XCTAssertTrue(netflix.isSelected)
    }

    @MainActor
    func testOfflineStreamingPickerDoesNotBlockTheTour() {
        let app = makeApp()
        app.launchEnvironment["CINEMATV_UI_TEST_STREAMING_FIXTURES"] = "offline"
        app.launch()
        openStreamingPicker(in: app)

        XCTAssertTrue(app.buttons["streaming.picker.retry"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["streaming.picker.save"].isEnabled)
        tap("streaming.picker.cancel", in: app)
        XCTAssertTrue(app.navigationBars["My Streaming Services"].waitForNonExistence(timeout: 5))
        tap("onboarding.next", in: app)
        assertChapter(Self.englishChapters[1], in: app)
    }

    @MainActor
    func testTourStreamingSelectionPrioritizesBothDiscoverFeeds() {
        let app = makeApp()
        app.launch()
        openStreamingPicker(in: app)
        tap("streaming.picker.provider.8", in: app)
        tap("streaming.picker.save", in: app)
        XCTAssertTrue(app.navigationBars["My Streaming Services"].waitForNonExistence(timeout: 5))
        tap("onboarding.skip", in: app)
        assertLibrary(in: app)

        app.tabBars.buttons["Discover"].tap()
        assertPreferredStreamingResults(in: app, feedID: "discover.movies.feed", otherProviderID: 9)

        let moviesFeed = app.scrollViews["discover.movies.feed"]
        // The segment picker can be hidden by the minimized toolbar after scrolling down.
        moviesFeed.swipeDown()
        let tvShows = app.segmentedControls.buttons["TV Shows"]
        for _ in 0..<4 where !tvShows.isHittable {
            moviesFeed.swipeDown()
        }
        XCTAssertTrue(tvShows.isHittable)
        tvShows.tap()
        assertPreferredStreamingResults(in: app, feedID: "discover.tv.feed", otherProviderID: 337)
    }

    @MainActor
    private func makeApp(language: String = "en", locale: String = "en_US") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["CINEMATV_UI_TEST_ONBOARDING"] = "1"
        app.launchEnvironment["CINEMATV_UI_TEST_STREAMING_FIXTURES"] = "1"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        return app
    }

    @MainActor
    private func openStreamingPicker(in app: XCUIApplication) {
        assertChapter(Self.englishChapters[0], in: app)
        tap("onboarding.streaming", in: app, scroll: true)
        XCTAssertTrue(app.navigationBars["My Streaming Services"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func assertPreferredStreamingResults(in app: XCUIApplication, feedID: String, otherProviderID: Int) {
        let feed = app.scrollViews[feedID]
        XCTAssertTrue(feed.waitForExistence(timeout: 5))
        let preferredResults = app.descendants(matching: .any)["streaming.results.8"].firstMatch
        let otherResults = app.descendants(matching: .any)["streaming.results.\(otherProviderID)"].firstMatch
        let seeOtherServices = app.buttons["streaming.seeOtherServices"]
        for _ in 0..<8 where !seeOtherServices.isHittable {
            feed.swipeUp()
        }
        XCTAssertTrue(preferredResults.waitForExistence(timeout: 5))
        XCTAssertFalse(otherResults.exists)
        XCTAssertTrue(seeOtherServices.isHittable)
        seeOtherServices.tap()

        for _ in 0..<4 where !otherResults.exists {
            feed.swipeUp()
        }
        XCTAssertTrue(otherResults.waitForExistence(timeout: 5))
        XCTAssertFalse(seeOtherServices.exists)
    }

    @MainActor
    private func advanceToFinalChapter(in app: XCUIApplication) {
        for (index, title) in Self.englishChapters.enumerated() {
            assertChapter(title, in: app)
            if index < Self.englishChapters.count - 1 {
                tap("onboarding.next", in: app)
            }
        }
    }

    @MainActor
    private func assertChapter(_ title: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let heading = app.staticTexts.matching(identifier: "onboarding.title")
            .matching(NSPredicate(format: "label == %@", title)).firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 5), "Expected chapter ‘\(title)’", file: file, line: line)
    }

    @MainActor
    private func assertLibrary(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.buttons["boxes.libraryEntry"].waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertFalse(app.staticTexts["onboarding.title"].exists, file: file, line: line)
    }

    @MainActor
    private func tap(_ identifier: String, in app: XCUIApplication, scroll: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[identifier].firstMatch
        if scroll {
            for _ in 0..<8 where !button.isHittable {
                app.swipeUp()
            }
        }
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button ‘\(identifier)’", file: file, line: line)
        button.tap()
    }
}
