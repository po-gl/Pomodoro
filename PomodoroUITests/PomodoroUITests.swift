//
//  PomodoroUITests.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 6/12/22.
//

import XCTest

final class PomodoroUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        let app = XCUIApplication()
        PomodoroUITests.resetTimer(app)
    }

    func testiOSUI_play_pause() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["playPauseButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOff"].exists, true)
        app.buttons["playPauseButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOff"].exists, false)
    }
    
    func testiOSUI_play_pause_reset() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["playPauseButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOff"].exists, true)
        app.buttons["playPauseButtonOn"].tap()
        app.buttons["resetButtonOn"].tap()
        XCTAssertEqual(app.buttons["resetButtonOn"].exists, true)
    }
    
    func testiOSUI_scrubProgressBar() throws {
        let app = XCUIApplication()
        app.launch()
        
        let progressBar = app.otherElements["DraggableProgressBar"]
        
        XCTAssertEqual(progressBar.exists, true)
        progressBar.swipeRight(velocity: 500)
        progressBar.swipeRight(velocity: 500)
        
        XCTAssertEqual(app.staticTexts["Work"].exists, false, "Expected false as the progressbar should be scrubbed close to the end")
        XCTAssertEqual(app.staticTexts["Long Break"].exists, true)
    }
    
    func testiOSUI_createTaskAndDrag() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Type task
        let taskText = app.textFields["AddTask"]
        taskText.tap()
        UIPasteboard.general.string = "TestContent"
        taskText.doubleTap()
        app.menuItems["Paste"].tap()
        
        // Drag to progress bar
        let task = app.otherElements["DraggableTask"]
        let progressBar = app.otherElements["DraggableProgressBar"]
        task.press(forDuration: 0.5, thenDragTo: progressBar)
        
        // Check if task label exists and delete it
        let taskLabel = app.buttons["TaskLabel_TestContent"]
        XCTAssertEqual(taskLabel.exists, true)
        
        taskLabel.tap()
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
