//
//  SettingsUITests.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 2/14/24.
//

import XCTest

final class SettingsUITests: XCTestCase {
    
    override class func setUp() {
        let app = XCUIApplication()
        app.launchWithDefaultsCleared()
        app.dismissWelcomeMessage()
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchAsUITest()
        app.buttons["settingsPage"].tap()
    }
    
    override func tearDownWithError() throws {
    }
    
    func testiOSUI_changeDurations() throws {
        let app = XCUIApplication()

        app.sliders["durationSliderWork"].adjust(toNormalizedSliderPosition: 0.0)
        app.sliders["durationSliderRest"].adjust(toNormalizedSliderPosition: 0.0)
        app.sliders["durationSliderLong Break"].adjust(toNormalizedSliderPosition: 0.0)

        XCTAssertEqual(app.staticTexts["durationValueWork"].label, "5:00")
        XCTAssertEqual(app.staticTexts["durationValueRest"].label, "3:00")
        XCTAssertEqual(app.staticTexts["durationValueLong Break"].label, "10:00")

        app.buttons["mainPage"].tap()
        XCTAssertEqual(app.staticTexts["timerDisplay"].label, "00:05:00", "Main page should reflect duration changes")

        app.buttons["settingsPage"].tap()
        app.buttons["resetDurationsButton"].tap()

        XCTAssertEqual(app.staticTexts["durationValueWork"].label, "25:00", "Durations should reset to defaults")
        XCTAssertEqual(app.staticTexts["durationValueRest"].label, "5:00", "Durations should reset to defaults")
        XCTAssertEqual(app.staticTexts["durationValueLong Break"].label, "30:00", "Durations should reset to defaults")
    }
    
    func testiOSUI_buddySettings() throws {
        let app = XCUIApplication()

        app.buttons["buddySelectorTomato"].tap()

        app.buttons["mainPage"].tap()
        XCTAssertEqual(app.images["buddyTomato"].exists, false, "Main page should reflect buddy changes")
        XCTAssertEqual(app.images["buddyBlueberry"].exists, true, "Main page should reflect buddy changes")
        XCTAssertEqual(app.images["buddyBanana"].exists, true, "Main page should reflect buddy changes")

        app.buttons["settingsPage"].tap()
        app.switches["buddyToggle"].switches.firstMatch.tap()

        XCTAssertEqual(app.images["buddyTomato"].exists, false)
        XCTAssertEqual(app.images["buddyBlueberry"].exists, false)
        XCTAssertEqual(app.images["buddyBanana"].exists, false)
    }
}
