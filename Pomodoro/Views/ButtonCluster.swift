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
        Button(action: {
            resetHaptic()
            withAnimation(.easeIn(duration: 0.2)){
                pomoTimer.reset()
            }
        }, label: {
            ZStack {
                RoundedRectangle(cornerRadius: 60)
                    .foregroundStyle(pomoTimer.isPaused ? Color("BarRest") : Color("GrayedOut"))
                    .frame(width: 130, height: 60)
                    .reverseMask {
                        Text("Reset")
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                    }
            }
        })
        .disabled(!pomoTimer.isPaused)
    }
    
    private func startStopButton() -> some View {
        Button(action: {
            basicHaptic()
            withAnimation(.easeIn(duration: 0.2)){
                pomoTimer.toggle()
            }
        }, label: {
            RoundedRectangle(cornerRadius: 60)
                .foregroundStyle(pomoTimer.isPaused ? Color("BarWork") : Color("BarLongBreak"))
                .opacity(pomoTimer.getStatus() == .end ? 0.5 : 1.0)
                .frame(width: 130, height: 60)
                .reverseMask {
                    Text(pomoTimer.isPaused ? (pomoTimer.getProgress() == 0.0 ? "Start" : "Resume") : "Stop")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                }
        })
        .disabled(pomoTimer.getStatus() == .end)
    }
}
