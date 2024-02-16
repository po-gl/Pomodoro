//
//  ChartsPageUITests.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 2/15/24.
//

import XCTest

final class ChartsPageUITests: XCTestCase {
    
    override class func setUp() {
        let app = XCUIApplication()
        app.launchWithDefaultsCleared()
        app.dismissWelcomeMessage()
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchAsUITest()
        app.buttons["chartsPage"].tap()
    }

    override func tearDownWithError() throws {
    }
    
    func testiOSUI_cumulativeTimes() throws {
        let app = XCUIApplication()

        app.buttons["cumulativeTimesCard"].tap()
    }
}
