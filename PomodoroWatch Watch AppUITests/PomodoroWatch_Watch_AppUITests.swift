//
//  PomodoroWatch_Watch_AppUITests.swift
//  PomodoroWatch Watch AppUITests
//
//  Created by Porter Glines on 10/23/22.
//

import XCTest

final class PomodoroWatch_Watch_AppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testWatchUI_play_pause() throws {
        let app = XCUIApplication()
        app.launch()

        let resetButton = app.images["resetButton"]
        let playButton = app.images["playPauseButton"]

        playButton.tap()
        XCTAssertEqual(resetButton.isEnabled, false)
        playButton.tap()
        XCTAssertEqual(resetButton.isEnabled, true)
    }

    func testWatchUI_play_pause_reset() throws {
        let app = XCUIApplication()
        app.launch()

        let resetButton = app.images["resetButton"]
        let playButton = app.images["playPauseButton"]

        playButton.tap()
        XCTAssertEqual(resetButton.isEnabled, false)
        playButton.tap()
        resetButton.tap()
        XCTAssertEqual(resetButton.isEnabled, true)
    }

    func testWatchUI_scrollToEnd() throws {
        let app = XCUIApplication()
        app.launch()

        XCUIDevice.shared.rotateDigitalCrown(delta: 9.0, velocity: 30.0)
        XCTAssert(app.staticTexts["Break"].exists)
        XCTAssert(app.staticTexts["🏖️"].exists)
        XCTAssert(app.staticTexts["00:01:00"].exists)
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
