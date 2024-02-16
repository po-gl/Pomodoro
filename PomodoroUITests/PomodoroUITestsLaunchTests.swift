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

    func testLaunch() throws {
        let app = XCUIApplication()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testScrubProgressBarScreen() throws {
        let app = XCUIApplication()

        let barCoords = app.otherElements["DraggableProgressBar"].coordinate(withNormalizedOffset: .zero)
        barCoords.press(forDuration: 0.1, thenDragTo: barCoords.withOffset(CGVector(dx: 400, dy: 0)))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Long Break Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTaskDragAndDropScreen() throws {
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

        wait(for: 0.2)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Task Added Screen"
        attachment.lifetime = .keepAlways
        self.add(attachment)

        // delete task
        let taskLabel = app.buttons["TaskLabel_TestContent"]
        taskLabel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
