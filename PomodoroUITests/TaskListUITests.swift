//
//  TaskListUITests.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 2/15/24.
//

import XCTest

final class TaskListUITests: XCTestCase {

    override class func setUp() {
        let app = XCUIApplication()
        app.launchWithDefaultsCleared()
        app.dismissWelcomeMessage()
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchAsUITest()
        app.buttons["taskList"].tap()
    }

    override func tearDownWithError() throws {
    }

    // MARK: TaskNote related tests

    func testiOSUI_addAndRemoveTaskWithNote() throws {
        let app = XCUIApplication()
        let testString = "TestTask\(Date.now.formatted(.iso8601))"
        let testNote = "TestNote"

        // Add a task
        app.buttons["newTaskButton"].tap()
        UIPasteboard.general.string = testString
        app.textViews["adderCell"].doubleTap()
        app.menuItems["Paste"].tap()
        app.buttons["doneButton"].tap()

        XCTAssertEqual(app.textViews[testString].exists, true, "Task cell should exist after adding it via adder cell")
        XCTAssertEqual(app.textViews[testString].value as? String ?? "", testString)

        // Add a note to the task
        app.textViews[testString].tapByCoord()
        app.textViews["\(testString)Note"].tap()
        UIPasteboard.general.string = testNote
        app.textViews["\(testString)Note"].doubleTap()
        app.menuItems["Paste"].tap()
        app.buttons["doneButton"].tap()

        XCTAssertEqual(app.textViews["\(testString)Note"].value as? String ?? "", testNote)

        app.textViews[testString].swipeRight()
        app.buttons["\(testString)DeleteButton"].tap()

        XCTAssertEqual(app.textViews[testString].exists, false, "Task cell should not exist after deleting it")
    }

    func testiOSUI_flagTaskWithSwipe() throws {
        let app = XCUIApplication()
        let taskString = "Task 0"

        XCTAssertEqual(app.images["\(taskString)FlagIndicator"].exists, false, "Flag indicator should not before flagging")

        app.textViews[taskString].swipeLeft()
        app.buttons["\(taskString)FlagButton"].tap()

        XCTAssertEqual(app.images["\(taskString)FlagIndicator"].exists, true, "Flag indicator on cell should exist after flagging")
    }

    func testiOSUI_addEstimationsInInfo() throws {
        let app = XCUIApplication()
        let testString = "TestTask\(Date.now.formatted(.iso8601))"
        addTask(testString)
        XCTAssertEqual(app.textViews[testString].waitForExistence(timeout: 0.1), true)

        app.textViews[testString].tapByCoord()
        app.buttons["\(testString)InfoButton"].tap()

        XCTAssertEqual(app.segmentedControls["pomosActualPicker"].exists, false, "Picker for actual pomos should not exist until the task is completed")

        app.segmentedControls["pomosEstimatePicker"].buttons["2"].tap()
        XCTAssertEqual(app.segmentedControls["pomosEstimatePicker"].buttons["2"].isSelected, true)

        app.switches["completedToggle"].switches.firstMatch.tap()
        app.segmentedControls["pomosActualPicker"].buttons["5"].tap()
        XCTAssertEqual(app.segmentedControls["pomosActualPicker"].buttons["5"].isSelected, true)

        // Back to task list
        app.buttons["doneButton"].tap()
        XCTAssertEqual(app.staticTexts["\(testString)EstimateOrActualPomos"].label, "5", "Estimation or actual pomos should be visible in cell info cluster in the task list")
    }

    func testiOSUI_completeTaskInList() throws {
        let app = XCUIApplication()
        let testString = "TestTask\(Date.now.formatted(.iso8601))"
        addTask(testString)
        XCTAssertEqual(app.textViews[testString].waitForExistence(timeout: 0.1), true)

        XCTAssertEqual(app.otherElements["\(testString)CheckIsOff"].exists, true, "Completed check should be off initially")
        app.otherElements["\(testString)CheckIsOff"].tapByCoord()
        XCTAssertEqual(app.otherElements["\(testString)CheckIsOn"].exists, true, "Completed check should be on after tapping")
    }

    // MARK: Project related tests
    
    func testiOSUI_openAndCollapseProjectStack() throws {
        let app = XCUIApplication()

        XCTAssertEqual(app.buttons["collapseProjectStackButton"].isHittable, false, "Project stack should initially be collapsed and collapse button should not be hittable")
        app.textViews["WorkProject"].tapByCoord()
        XCTAssertEqual(app.buttons["collapseProjectStackButton"].isHittable, true, "Project stack should be opened now and the collapse button should be hittable")
        app.buttons["collapseProjectStackButton"].tap()
        XCTAssertEqual(app.buttons["collapseProjectStackButton"].isHittable, false, "Project stack should now be collapsed and collapse button should not be hittable")
    }

    func testiOSUI_addAndRemoveProjectWithNote() throws {
        let app = XCUIApplication()
        let testString = "TestProject\(UUID().uuidString.prefix(6))"
        let testNote = "TestNote"
        openProjectStack()

        // Add a project
        app.buttons["addProjectButton"].tap()
        UIPasteboard.general.string = testString
        app.textViews["Project"].doubleTap()
        app.menuItems["Paste"].tap()
        app.buttons["doneButton"].tap()

        XCTAssertEqual(app.textViews["\(testString)Project"].exists, true, "Project should exist after adding it")
        XCTAssertEqual(app.textViews["\(testString)Project"].value as? String ?? "", testString)

        // Add a note to the project
        app.textViews["\(testString)Project"].tapByCoord()
        app.textViews["\(testString)ProjectNote"].tap()
        UIPasteboard.general.string = testNote
        app.textViews["\(testString)ProjectNote"].doubleTap()
        app.menuItems["Paste"].tap()
        app.buttons["doneButton"].tap()

        XCTAssertEqual(app.textViews["\(testString)ProjectNote"].value as? String ?? "", testNote)

        // Delete project
        app.textViews["\(testString)Project"].swipeRight()
        app.buttons["\(testString)ProjectDeleteButton"].tap()

        XCTAssertEqual(app.textViews["\(testString)Project"].exists, false, "Project should not exist after deleting it")
    }
    
    func testiOSUI_archiveAndUnarchiveProjectInList() throws {
        let app = XCUIApplication()
        let testString = "TestProject\(UUID().uuidString.prefix(6))"
        openProjectStack()

        addProject(testString)

        // Archive project
        app.textViews["\(testString)Project"].byCoord().referencedElement.swipeLeft()
        app.buttons["\(testString)ProjectArchiveToggleButton"].tap()

        XCTAssertEqual(app.textViews["\(testString)Project"].exists, false, "An archived project should be removed from the task list")

        // Navigate to archived projects list
        app.buttons["taskListOverflowMenu"].tapByCoord()
        app.buttons["showArchivedProjectsButton"].tap()

        XCTAssertEqual(app.textViews["\(testString)Project"].exists, true, "The archived project should exist in the archived projects list")

        // Unarchive project
        app.textViews["\(testString)Project"].byCoord().referencedElement.swipeLeft()
        app.buttons["\(testString)ProjectArchiveToggleButton"].tap()

        navigateBack()
        XCTAssertEqual(app.textViews["\(testString)Project"].exists, true, "The archived project should exist in the archived projects list")
    }

    func testiOSUI_setProjectAsTopThenAssignAndRemoveTaskFromTopProject() throws {
        let app = XCUIApplication()
        let testProject = "TestProject\(UUID().uuidString.prefix(6))"
        let testTask = "Task 0"
        openProjectStack()
        addProject(testProject)

        // Set newly added project as top project
        app.textViews["\(testProject)Project"].byCoord().referencedElement.swipeLeft()
        app.buttons["\(testProject)ProjectSendToTopButton"].tapByCoord()

        app.buttons["collapseProjectStackButton"].tap()

        app.textViews[testTask].byCoord().referencedElement.swipeLeft()
        app.buttons["\(testTask)AssignToTopProjectButton"].tap()

        // Check project assignment in info cluster
        XCTAssertEqual(app.otherElements["\(testTask):\(testProject)TinyTag"].exists, true, "Project tiny tag should exist after assigning task to project")

        // Check project assignment in task info
        app.textViews[testTask].tapByCoord()
        app.buttons["\(testTask)InfoButton"].tap()

        XCTAssertEqual(app.buttons["\(testProject)ProjectTag"].exists, true, "Project tag should also exist in task info")

        // Unassign task from project
        app.byCoord().referencedElement.swipeUp()
        app.buttons["editAssignedProjectsButton"].tap()
        app.buttons["\(testProject)ProjectTag"].tap()
        app.buttons["editAssignedProjectsButton"].tap()

        app.buttons["doneButton"].tap()
        XCTAssertEqual(app.otherElements["\(testTask):\(testProject)TinyTag"].exists, false, "Task should now be unassigned from project")
    }

    private func addTask(_ text: String) {
        let app = XCUIApplication()
        app.buttons["newTaskButton"].tap()
        UIPasteboard.general.string = text
        app.textViews["adderCell"].doubleTap()
        app.menuItems["Paste"].tap()
        app.buttons["doneButton"].tap()
    }

    private func addProject(_ text: String) {
        let app = XCUIApplication()
        app.buttons["addProjectButton"].tap()
        UIPasteboard.general.string = text
        app.textViews["Project"].doubleTap()
        app.menuItems["Paste"].tap()
        app.buttons["doneButton"].tap()
    }

    private func openProjectStack() {
        let app = XCUIApplication()
        if !app.buttons["collapseProjectStackButton"].isHittable {
            app.textViews["WorkProject"].tapByCoord()
        }
    }
}
