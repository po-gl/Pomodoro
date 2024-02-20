//
//  MainPageUITests.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 6/12/22.
//

import XCTest

final class MainPageUITests: XCTestCase {

    override class func setUp() {
        let app = XCUIApplication()
        app.launchWithDefaultsCleared()
        app.dismissWelcomeMessage()
    }

    override func setUpWithError() throws {
        let app = XCUIApplication()
        app.launchAsUITest()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        let app = XCUIApplication()
        MainPageUITests.resetTimer(app)
    }
    
    func testiOSUI_play_pause() throws {
        let app = XCUIApplication()

        app.buttons["playPauseButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOff"].exists, true)
        app.buttons["playPauseButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOff"].exists, false)
    }

    func testiOSUI_play_pause_reset() throws {
        let app = XCUIApplication()

        app.buttons["playPauseButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOff"].exists, true)
        app.buttons["playPauseButtonOn"].tap()
        app.buttons["resetButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOn"].exists, true)
    }

    func testiOSUI_scrubProgressBar() throws {
        let app = XCUIApplication()

        let barCoords = app.otherElements["DraggableProgressBar"].byCoord()
        barCoords.press(forDuration: 0.1, thenDragTo: barCoords.withOffset(CGVector(dx: 300, dy: 0)))

        XCTAssertEqual(app.staticTexts["Work"].exists, false, "Expected false as the progressbar should be scrubbed close to the end")
        XCTAssertEqual(app.staticTexts["Long Break"].exists, true)
    }

    func testiOSUI_changePomos() throws {
        let app = XCUIApplication()

        XCTAssertEqual(app.staticTexts["pomoStepperValue"].label.trimmingCharacters(in: .whitespaces), "4")
        app.buttons["pomoStepper-Decrement"].tap()
        XCTAssertEqual(app.staticTexts["pomoStepperValue"].label.trimmingCharacters(in: .whitespaces), "3")
        app.buttons["pomoStepper-Increment"].tap()
        XCTAssertEqual(app.staticTexts["pomoStepperValue"].label.trimmingCharacters(in: .whitespaces), "4")
    }

    func testiOSUI_createTaskAndDrag() throws {
        let app = XCUIApplication()

        // Type task
        let taskText = app.textFields["AddTask"]
        taskText.tap()
        UIPasteboard.general.string = "TestContent"
        taskText.doubleTap()
        app.menuItems["Paste"].tap()

        // Drag to progress bar
        let draggableTask = app.otherElements["DraggableTask"]
        let progressBar = app.otherElements["DraggableProgressBar"]
        draggableTask.swipeDown() // Swipe to dismiss keyboard so progress bar is hittable
        draggableTask.press(forDuration: 0.1, thenDragTo: progressBar)

        // Check if task label exists and delete it
        let taskLabel = app.buttons["TaskLabel_TestContent"]
        XCTAssertEqual(taskLabel.waitForExistence(timeout: 0.2), true)

        taskLabel.tapByCoord()
        app.buttons["DeleteTask"].tap()

        XCTAssertEqual(taskLabel.exists, false)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    static func resetTimer(_ app: XCUIApplication) {
        if app.buttons["resetButtonOn"].exists {
            app.buttons["resetButtonOn"].tap()
        } else {
            app.buttons["playPauseButtonOn"].tap()
            app.buttons["resetButtonOn"].tap()
        }
    }
}
