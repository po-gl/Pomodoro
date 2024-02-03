//
//  StartStop.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/15/23.
//

import SwiftUI
import AppIntents
#if canImport(ActivityKit)
import ActivityKit
#endif
import OSLog

@available(iOS 17.0, *)
struct StartStop: LiveActivityIntent {

    static var title: LocalizedStringResource = "Pomo Start Stop Button"
    static var description = IntentDescription("Start or stop the pomodoro session.")

    func perform() async throws -> some IntentResult {
        Logger().log("Live activity intent performing start/stop")

        let pomoTimer = PomoTimer()
        pomoTimer.restoreFromUserDefaults()
        pomoTimer.toggle()

        let tasksOnBar = TasksOnBar()
        tasksOnBar.restoreFromUserDefaults()

#if canImport(ActivityKit)
        if pomoTimer.isPaused {
            LiveActivities.shared.stopLiveActivity(pomoTimer, tasksOnBar)
        } else {
            LiveActivities.shared.setupLiveActivity(pomoTimer, tasksOnBar)
        }
#endif

        pomoTimer.saveToUserDefaults()
        return .result()
    }
}
