//
//  TimerDisplay.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI


struct TimerDisplay: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\(pomoTimer.getStatusString(atDate: context.date))")
                        .font(.system(size: 30, weight: .light, design: .monospaced))
                        .colorScheme(.dark)
                        .padding(.horizontal, 4)
                        .background(Rectangle().foregroundColor(colorScheme == .dark ? .black : getColorForStatus(pomoTimer.getStatus(atDate: context.date))))
                    Spacer()
                }
                Text("\(pomoTimer.timeRemaining(atDate: context.date).timerFormatted())")
                    .font(.system(size: 70, weight: .light))
                    .monospacedDigit()
                    .shadow(radius: 20)
                    .colorScheme(colorScheme == .dark ? .light : .dark)
                HStack(spacing: 0) {
                    Spacer()
                    Text("\(Array(repeating: "🍅", count: pomoTimer.pomoCount).joined(separator: ""))")
                        .font(.system(size: 12))
                    Text("Pomos")
                        .font(.system(size: 25, weight: .ultraLight))
                        .colorScheme(colorScheme == .dark ? .light : .dark)
                        .padding(.horizontal, 5)
                    if pomoTimer.isPaused {
                        pomoStepper()
                            .colorScheme(colorScheme == .dark ? .light : .dark)
                            .scaleEffect(0.8)
                            .frame(width: 80)
                    }
                }
                .padding(.trailing, 6)
            }
            .frame(width: 285)
            .animation(.easeInOut(duration: 0.2), value: pomoTimer.getStatus(atDate: context.date))
        }
    }
    
    
    private func pomoStepper() -> some View {
        return Stepper {
            } onIncrement: {
                basicHaptic()
                withAnimation(.easeInOut(duration: 0.2)) {
                    pomoTimer.incrementPomos()
                }
            } onDecrement: {
                basicHaptic()
                withAnimation(.easeInOut(duration: 0.2)) {
                    pomoTimer.decrementPomos()
                }
            }
    }
    
    
    private func getColorForStatus(_ status: PomoStatus) -> Color {
        switch status {
        case .work:
            return Color("BarWork")
        case .rest:
            return Color("BarRest")
        case .longBreak:
            return Color("BarLongBreak")
        case .end:
            return .accentColor
        }
    }
    
    
    private func getIconForStatus(status: PomoStatus) -> String {
        switch status {
        case .work:
            return "🌶️"
        case .rest:
            return "🍈🍉🫐"
        case .longBreak:
            return "🏖️"
        case .end:
            return "🎉"
        }
    }
}
