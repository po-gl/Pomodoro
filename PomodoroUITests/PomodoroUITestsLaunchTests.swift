//
//  PomodoroUITestsLaunchTests.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 6/12/22.
//

import XCTest

final class PomodoroUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        let app = XCUIApplication()
        PomodoroUITests.resetTimer(app)
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testScrubProgressBarScreen() throws {
        let app = XCUIApplication()
        app.launch()
        
        let progressBar = app.otherElements["DraggableProgressBar"]
        progressBar.swipeRight(velocity: 500)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Long Break Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testTaskDragAndDropScreen() throws {
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
        
        wait(for: 1)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Task Added Screen"
        attachment.lifetime = .keepAlways
        self.add(attachment)
        
        // delete task
        let taskLabel = app.buttons["TaskLabel_TestContent"]
        taskLabel.tap()
        app.buttons["DeleteTask"].tap()
    }
    
    
    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            waitExpectation.fulfill()
        }
        
        waitForExpectations(timeout: duration + 0.5)
    }
}
