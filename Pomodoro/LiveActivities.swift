//
//  LiveActivities.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/23/23.
//

import ActivityKit
import WidgetKit
import SwiftUI
import BackgroundTasks

@available(iOS 16.2, *)
func setupLiveActivity(_ pomoTimer: PomoTimer) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    guard !pomoTimer.isPaused else { return }

    let attributes = PomoAttributes()
    let content = getLiveActivityContent(pomoTimer)

    do {
        let activity = try Activity.request(attributes: attributes, content: content)
        print("Requested live activity \(String(describing: activity.id)).")
    } catch {
        print("Error requesting live activity \(error.localizedDescription).")
    }
}

@available(iOS 16.2, *)
private func getLiveActivityContent(_ pomoTimer: PomoTimer) -> ActivityContent<PomoAttributes.LivePomoState> {
    let state = PomoAttributes.LivePomoState(
        status: pomoTimer.getStatus(),
        timer: Date.now...Date.now.addingTimeInterval(pomoTimer.timeRemaining()),
        currentPomo: pomoTimer.currentPomo(),
        pomoCount: pomoTimer.pomoCount)
    return ActivityContent(state: state, staleDate: nil)
}

@available(iOS 16.2, *)
func cancelLiveActivity() {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    let finalStatus = PomoAttributes.LivePomoState(status: .end, timer: Date.now...Date(), currentPomo: 4, pomoCount: 4)
    let finalContent = ActivityContent(state: finalStatus, staleDate: nil)
    Task {
        for activity in Activity<PomoAttributes>.activities {
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
    }

    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.po-gl.Pomodoro.LiveActivityRefresh")
}
