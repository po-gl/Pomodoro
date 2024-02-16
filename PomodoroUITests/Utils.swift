//
//  Utils.swift
//  PomodoroUITests
//
//  Created by Porter Glines on 2/14/24.
//

import XCTest

extension XCUIApplication {
    func launchWithDefaultsCleared() {
        self.launchArguments += ["-resetUserDefaults"]
        self.launch()
    }

    func launchAsUITest() {
        self.launchArguments += ["-isUITest"]
        self.launch()
    }

    func dismissWelcomeMessage() {
        if self.buttons["skipWelcomeButton"].exists {
            self.buttons["skipWelcomeButton"].tap()
        }
    }
}

func navigateBack() {
    XCUIApplication().navigationBars.buttons.element(boundBy: 0).tap()
}
