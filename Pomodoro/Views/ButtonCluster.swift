//
//  ButtonCluster.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/21/22.
//

import Foundation
import SwiftUI
    

struct ButtonCluster: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)) { context in
            ZStack {
                HStack(spacing: 0) {
                    Spacer()
                    ResetButton()
                    Spacer()
                    StartStopButton()
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private func ResetButton() -> some View {
        let isEnabled = pomoTimer.isPaused || pomoTimer.getStatus() == .end
        Button("Reset") {
            guard isEnabled else { return }
            resetHaptic()
            withAnimation(.easeIn(duration: 0.2)){ pomoTimer.reset() }
        }
        .accessibilityIdentifier("resetButton\(isEnabled ? "On" : "Off")")
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: isEnabled ? Color("BarRest") : Color("GrayedOut")))
        .foregroundColor(isEnabled ? .black : .white)
    }
    
    @ViewBuilder
    private func StartStopButton() -> some View {
        let isEnabled = pomoTimer.getStatus() != .end
        Button(getStartStopButtonString()) {
            guard isEnabled else { return }
            basicHaptic()
            withAnimation { pomoTimer.toggle() }
            EndTimerHandler.shared.hasEndFired = false
        }
        .accessibilityIdentifier("playPauseButton\(isEnabled ? "On" : "Off")")
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: getStartStopButtonColor()))
        .foregroundColor(isEnabled ? .black : .white)
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
            return Color("GrayedOut")
        } else if pomoTimer.isPaused {
            return Color("BarWork")
        }
        return Color("BarLongBreak")
    }
}
