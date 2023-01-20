//
//  TimerDisplay.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import SwiftUI

struct TimerDisplay: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack(alignment: .leading) {
                HStack {
                    Text("\(getStringForStatus(pomoTimer.getStatus(atDate: context.date)))")
                        .accessibilityIdentifier("statusString")
                        .foregroundColor(isLuminanceReduced ? getColorForStatus(pomoTimer.getStatus(atDate: context.date)) : .black)
                        .padding(.horizontal, 4)
                        .background(Rectangle().foregroundColor(isLuminanceReduced ? .black : getColorForStatus(pomoTimer.getStatus(atDate: context.date))))
                        .font(.system(size: 21, weight: .light, design: .monospaced))
                    Spacer()
                    Text(getIconForStatus(status: pomoTimer.getStatus(atDate: context.date)))
                        .font(.system(size: 20))
                }
                    .frame(width: 145)
                Text("\(pomoTimer.timeRemaining(atDate: context.date).timerFormatted())")
                    .accessibilityIdentifier("timeRemaining")
                    .font(.system(size: 40, weight: .regular))
                    .monospacedDigit()
            }
        }
    }
    
    func getStringForStatus(_ status: PomoStatus) -> String {
        switch status {
        case .work:
            return "Work"
        case .rest:
            return "Rest"
        case .longBreak:
            return "Break"
        case .end:
            return "Finished"
        }
    }
    
    func getColorForStatus(_ status: PomoStatus) -> Color {
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
}
