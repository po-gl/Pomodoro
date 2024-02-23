//
//  OnBoardingUITests.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 2/15/24.
//

import XCTest

final class OnBoardingUITests: XCTestCase {
    
    override class func setUp() {
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchArguments += ["-usePreviewData"]
        app.launchWithDefaultsCleared()
    }

    override func tearDownWithError() throws {
    }

    func testiOSUI_onBoardingSkip() throws {
        let app = XCUIApplication()

        app.buttons["skipWelcomeButton"].tap()

        XCTAssertEqual(app.staticTexts["timerDisplay"].isHittable, true, "Main page should now be visible")
    }
    
    func testiOSUI_onBoardingFull() throws {
        let app = XCUIApplication()

        app.collectionViews["onBoardingTabView"].swipeLeft()
        app.collectionViews["onBoardingTabView"].swipeLeft()

        app.buttons["getStartedButton"].tap()
        XCTAssertEqual(app.staticTexts["timerDisplay"].isHittable, true, "Main page should now be visible")
    }
}
