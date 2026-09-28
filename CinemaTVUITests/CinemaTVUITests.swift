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
