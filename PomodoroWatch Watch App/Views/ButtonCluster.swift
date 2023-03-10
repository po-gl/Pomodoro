//
//  ButtonCluster.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import SwiftUI
    

struct ButtonCluster: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        HStack {
            ResetButton()
            Spacer()
            StartStopButton()
        }
    }
    
    @ViewBuilder
    private func ResetButton() -> some View {
        let isEnabled = pomoTimer.isPaused || pomoTimer.getStatus() == .end
        Image(systemName: withFill("arrow.counterclockwise.circle"))
            .accessibilityIdentifier("resetButton")
            .foregroundColor(pomoTimer.isPaused ? .orange : Color(hex: 0x333333))
            .font(.system(size: 40))
            .onTapGesture {
                guard isEnabled else { return }
                resetHaptic()
                pomoTimer.unpause() // to update crown scroll progress
                withAnimation(.easeIn(duration: 0.2)){
                    pomoTimer.reset()
                    pomoTimer.pause()
                }
            }
            .disabled(!isEnabled)
    }
    
    @ViewBuilder
    private func StartStopButton() -> some View {
        let isEnabled = pomoTimer.getStatus() != .end
        Image(systemName: pomoTimer.isPaused ? withFill("play.circle") : withFill("pause.circle"))
            .accessibilityIdentifier("playPauseButton")
            .foregroundColor(.accentColor)
            .font(.system(size: 40))
            .onTapGesture {
                guard isEnabled else { return }
                pomoTimer.isPaused ? startHaptic() : stopHaptic()
                withAnimation(.easeIn(duration: 0.2)){
                    pomoTimer.toggle()
                }
            }
            .disabled(!isEnabled)
    }
    
    private func withFill(_ systemName: String) -> String {
        return isLuminanceReduced ? systemName : systemName + ".fill"
    }
}
