//
//  TimerDisplay.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import SwiftUI

struct TimerDisplay: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack(alignment: .leading) {
                HStack {
                    Text("\(pomoTimer.getStatusString(atDate: context.date))")
                        .foregroundColor(getColorForStatus(pomoTimer.getStatus(atDate: context.date)))
                        .font(.system(size: 26))
                        .fontWeight(.light)
                    Spacer()
                    Text(getIconForStatus(status: pomoTimer.getStatus(atDate: context.date)))
                        .font(.system(size: 20))
                }
                    .frame(width: 145)
                Text("\(pomoTimer.timeRemaining(atDate: context.date).timerFormatted())")
                    .font(.system(size: 40))
                    .fontWeight(.regular)
                    .monospacedDigit()
                    .shadow(radius: 20)
            }
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
            return "🍈"
        case .longBreak:
            return "🏖️"
        case .end:
            return "🎉"
        }
    }
}
