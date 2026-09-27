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
    func testMoviesShowAvailableNetflixReleases() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["CINEMATV_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Discover"].firstMatch.tap()
        assertStreamingResults(in: app, feedID: "discover.movies.feed")
    }

    @MainActor
    func testTVShowsShowAvailableNetflixReleases() throws {
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

        let streaming = app.staticTexts["New releases to stream"]
        for _ in 0..<8 where !streaming.exists {
            feed.swipeUp()
        }
        XCTAssertTrue(streaming.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["streaming.provider.8"].waitForExistence(timeout: 30))
        XCTAssertTrue(
            app.descendants(matching: .any)["streaming.results"]
                .waitForExistence(timeout: 30)
        )
    }
}
