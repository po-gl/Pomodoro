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
    
    var pomoChangeAnimation: Animation = .interpolatingSpring(stiffness: 190, damping: 13)
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack(alignment: .leading, spacing: 0) {
                // TOP
                HStack(alignment: .bottom, spacing: 0) {
                    Text("\(pomoTimer.getStatusString(atDate: context.date))")
                        .font(.system(size: 30, weight: .thin, design: .serif))
                        .foregroundColor(colorScheme == .dark ? getColorForStatus(pomoTimer.getStatus(atDate: context.date)) : .black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Rectangle().foregroundColor(colorScheme == .dark ? .black : getColorForStatus(pomoTimer.getStatus(atDate: context.date))))
                    Spacer()
                    HStack(alignment: .bottom, spacing: 5) {
                        Text("\(pomoTimer.getStatus(atDate: context.date) == .longBreak ? "" : "until ")\(context.date.addingTimeInterval(pomoTimer.timeRemaining(atDate: context.date)), formatter: timeFormatter)")
                            .colorScheme(colorScheme == .dark ? .light : .dark)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .monospacedDigit()
                            .opacity(pomoTimer.isPaused ? 0.5 : 1.0)
                        Text("\(getIconForStatus(status: pomoTimer.getStatus(atDate: context.date)))")
                            .font(.system(size: 15))
                            .offset(y: -3)
                    }
                    .offset(x: -5, y: 4)
                }
                // MIDDLE
                Text("\(pomoTimer.timeRemaining(atDate: context.date).timerFormatted())")
                    .font(.system(size: 70, weight: .light))
                    .monospacedDigit()
                    .colorScheme(colorScheme == .dark ? .light : .dark)
                
                // BOTTOM
                HStack(spacing: 0) {
                    Spacer()
                    Text("\(Array(repeating: "🍅", count: pomoTimer.pomoCount).joined(separator: ""))")
                        .font(.system(size: 12))
                    Text("Pomos")
                        .font(.system(size: 23, weight: .light))
                        .colorScheme(colorScheme == .dark ? .light : .dark)
                        .padding(.horizontal, 5)
                    pomoStepper()
                        .colorScheme(colorScheme == .dark ? .light : .dark)
                        .scaleEffect(0.8)
                        .frame(width: pomoTimer.isPaused ? 80 : 0)
                        .opacity(pomoTimer.isPaused ? 1 : 0)
                }
                .animation(.interpolatingSpring(stiffness: 270, damping: 24), value: pomoTimer.isPaused)
                .frame(height: 30)
                .padding(.trailing, 6)
            }
            .frame(width: 285, height: 160)
            .animation(.easeInOut(duration: 0.2), value: pomoTimer.getStatus(atDate: context.date))
        }
    }
    
    
    private func pomoStepper() -> some View {
        return Stepper {
            } onIncrement: {
                basicHaptic()
                withAnimation(pomoChangeAnimation) {
                    pomoTimer.incrementPomos()
                }
            } onDecrement: {
                basicHaptic()
                withAnimation(pomoChangeAnimation) {
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
            return "🍇"
        case .longBreak:
            return "🏖️"
        case .end:
            return "🎉"
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("hh:mm")
        return formatter
    }()
}
