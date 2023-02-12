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
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
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
        Button("Reset") {
            guard pomoTimer.isPaused || pomoTimer.getStatus() == .end else { return }
            resetHaptic()
            withAnimation(.easeIn(duration: 0.2)){ pomoTimer.reset() }
        }
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: pomoTimer.isPaused || pomoTimer.getStatus() == .end ? Color("BarRest") : Color("GrayedOut")))
    }
    
    @ViewBuilder
    private func StartStopButton() -> some View {
        Button(getStartStopButtonString()) {
            guard pomoTimer.getStatus() != .end else { return }
            basicHaptic()
            withAnimation { pomoTimer.toggle() }
        }
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: getStartStopButtonColor()))
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
