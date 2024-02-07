//
//  ButtonCluster.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/21/22.
//

import Foundation
import SwiftUI

struct ButtonCluster: View {
    @EnvironmentObject var pomoTimer: PomoTimer

    var startStopAnimation: Animation = .interpolatingSpring(stiffness: 190, damping: 13)

    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)) { _ in
            ZStack {
                HStack(spacing: 0) {
                    Spacer()
                    resetButton
                    Spacer()
                    startStopButton
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder private var resetButton: some View {
        let isEnabled = pomoTimer.isPaused || pomoTimer.getStatus() == .end
        Button("Reset") {
            guard isEnabled else { return }
            resetHaptic()
            withAnimation(.easeIn(duration: 0.2)) { pomoTimer.reset() }
        }
        .accessibilityIdentifier("resetButton\(isEnabled ? "On" : "Off")")
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: isEnabled ? .barRest : .grayedOut))
        .foregroundColor(isEnabled ? .black : .white)
        .animation(.default, value: pomoTimer.isPaused)
    }

    @ViewBuilder private var startStopButton: some View {
        let isEnabled = pomoTimer.getStatus() != .end
        Button(getStartStopButtonString()) {
            guard isEnabled else { return }
            basicHaptic()
            withAnimation(startStopAnimation) { pomoTimer.toggleAndRecord() }
            EndTimerHandler.shared.hasEndFired = false
        }
        .accessibilityIdentifier("playPauseButton\(isEnabled ? "On" : "Off")")
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: getStartStopButtonColor()))
        .foregroundColor(isEnabled ? .black : .white)
        .animation(.default, value: pomoTimer.isPaused)
    }

    private func getStartStopButtonString() -> String {
        if pomoTimer.getStatus() == .end {
            return "Start"
        } else if pomoTimer.isPaused {
            if pomoTimer.getProgress() == 0.0 {
               return "Start"
            }
            return "Resume"
        }
        return "Stop"
    }

    private func getStartStopButtonColor() -> Color {
        if pomoTimer.getStatus() == .end {
            return .grayedOut
        } else if pomoTimer.isPaused {
            return .barWork
        }
        return .barLongBreak
    }
}
