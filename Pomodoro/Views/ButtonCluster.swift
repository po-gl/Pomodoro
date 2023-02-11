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
        ZStack {
            HStack(spacing: 0) {
                Spacer()
                resetButton()
                Spacer()
                startStopButton()
                Spacer()
            }
        }
    }
    
    private func resetButton() -> some View {
        Button("Reset") {
            resetHaptic()
            withAnimation(.easeIn(duration: 0.2)){ pomoTimer.reset() }
        }
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: pomoTimer.isPaused ? Color("BarRest") : Color("GrayedOut")))
        .disabled(!pomoTimer.isPaused)
    }
    
    private func startStopButton() -> some View {
        Button(pomoTimer.isPaused ? (pomoTimer.getProgress() == 0.0 ? "Start" : "Resume") : "Stop") {
            basicHaptic()
            withAnimation { pomoTimer.toggle() }
        }
        .frame(width: 130, height: 60)
        .buttonStyle(PopStyle(color: pomoTimer.isPaused ? Color("BarWork") : Color("BarLongBreak")))
        .opacity(pomoTimer.getStatus() == .end ? 0.5 : 1.0)
        .disabled(pomoTimer.getStatus() == .end)
    }
}
