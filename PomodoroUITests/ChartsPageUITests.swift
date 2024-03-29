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
    
    func testiOSUI_cumulativeTimesChartTitle_dailyAndWeekly() throws {
        let app = XCUIApplication()
        app.buttons["cumulativeTimesCard"].tap()
        
        XCTAssertGreaterThan(Double(app.staticTexts["totalHourValue"].label) ?? 0, 0.0)
        XCTAssertEqual(app.staticTexts["visibleDate"].label, Date.now.formatted(.dateTime.weekday().month().day().year()))

        app.segmentedControls["chartScalePicker"].buttons["Weekly"].tap()

        XCTAssertGreaterThan(Double(app.staticTexts["totalHourValue"].label) ?? 0, 0.0)
        let startOfWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now).date!
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)! - 1.0
        let visibleDateRange = "\(startOfWeek.formatted(.dateTime.month().day())) - \(endOfWeek.formatted(.dateTime.month().day().year()))"
        XCTAssertEqual(app.staticTexts["visibleDate"].label, visibleDateRange)
    }

    func testiOSUI_cumulativeTimesAverages() throws {
        let app = XCUIApplication()
        app.buttons["cumulativeTimesCard"].tap()
        
        app.buttons["chartToggleDaily Average"].tap()
        
        let averageMark = app.otherElements["averageMark\(Calendar.current.startOfDay(for: Date.now).formatted(.iso8601))"].value as? String ?? ""
        XCTAssertGreaterThan(Double(averageMark) ?? 0.0, 0.0)
    }

    func testiOSUI_cumulativeTimesDeleteData() throws {
        let app = XCUIApplication()
        app.buttons["cumulativeTimesCard"].tap()
        
        app.buttons["allDataButton"].tap()
        app.buttons["editButton"].tap()

        app.buttons["deleteAllButton"].tap()
        app.buttons["confirmDeleteAllButton"].tap()

        navigateBack()
        XCTAssertEqual(Double(app.staticTexts["totalHourValue"].label) ?? -1, 0.0, accuracy: 0.01)
    }

    func testiOSUI_pomoEstimationsChartTitle() throws {
        let app = XCUIApplication()
        app.buttons["pomodoroEstimationsCard"].tap()
        
        XCTAssertGreaterThan(Double(app.staticTexts["estimatesAverageValue"].label) ?? 0, 0.0)
        XCTAssertGreaterThan(Double(app.staticTexts["actualsAverageValue"].label) ?? 0, 0.0)

        let startOfWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now).date!
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)! - 1.0
        let visibleDateRange = "\(startOfWeek.formatted(.dateTime.month().day())) - \(endOfWeek.formatted(.dateTime.month().day().year()))"
        XCTAssertEqual(app.staticTexts["visibleDate"].label, visibleDateRange)
    }

    func testiOSUI_completedChartTitle() throws {
        let app = XCUIApplication()
        app.buttons["tasksCompletedCard"].tap()

        XCTAssertGreaterThan(Int(app.staticTexts["countValue"].label) ?? 0, 0)

        let startOfWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now).date!
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)! - 1.0
        let visibleDateRange = "\(startOfWeek.formatted(.dateTime.month().day())) - \(endOfWeek.formatted(.dateTime.month().day().year()))"
        XCTAssertEqual(app.staticTexts["visibleDate"].label, visibleDateRange)
    }

    func testiOSUI_completedChartAverages() throws {
        let app = XCUIApplication()
        app.buttons["tasksCompletedCard"].tap()

        app.buttons["chartToggleWeekly Average"].tap()

        let startOfWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now).date!
        let averageMark = app.otherElements["averageMark\(startOfWeek.formatted(.iso8601))"].value as? String ?? ""
        XCTAssertGreaterThan(Double(averageMark) ?? 0.0, 0.0)
    }
}
