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
            VStack(alignment: .leading) {
                HStack {
                    Text("\(pomoTimer.getStatusString(atDate: context.date))")
                        .foregroundColor(colorScheme == .dark ? getColorForStatus(pomoTimer.getStatus(atDate: context.date)) : .primary)
                        .font(.system(size: 30))
                        .fontWeight(.light)
                    Spacer()
                    Text(getIconForStatus(status: pomoTimer.getStatus(atDate: context.date)))
                        .font(.system(size: 30))
                        .shadow(radius: 20)
                }
                Text("\(pomoTimer.timeRemaining(atDate: context.date).timerFormatted())")
                    .font(.system(size: 70))
                    .fontWeight(.light)
                    .monospacedDigit()
                    .shadow(radius: 20)
                HStack {
                    Spacer()
                    Text("\(Array(repeating: "🍅", count: pomoTimer.pomoCount).joined(separator: ""))")
                        .font(.system(size: 22))
                    Text("Pomos")
                        .font(.system(size: 30))
                        .fontWeight(.ultraLight)
                }
                
                pomoStepper()
                    .opacity(pomoTimer.isPaused ? 1.0 : 0.0)
            }
            .frame(width: 285)
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
