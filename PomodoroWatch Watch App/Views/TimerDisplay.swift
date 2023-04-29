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
            VStack(alignment: .center) {
                ZStack {
                    HStack {
                        StatusBox(at: context.date)
                        EndingTime(at: context.date)
                            .offset(y: 4)
                        
                    }
                    HStack {
                        Spacer()
                        StatusIcon(at: context.date)
                            .padding(.trailing, 15)
                            .offset(y: -15)
                    }
                }
                TimerView(at: context.date)
            }
        }
    }
    
    
    @ViewBuilder
    private func StatusBox(at date: Date) -> some View {
        let color = isLuminanceReduced ? .black : getColorForStatus(pomoTimer.getStatus(atDate: date))
        
        Text("\(getStringForStatus(pomoTimer.getStatus(atDate: date)))")
            .accessibilityIdentifier("statusString")
            .foregroundColor(isLuminanceReduced ? getColorForStatus(pomoTimer.getStatus(atDate: date)) : .black)
            .padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 5).foregroundColor(color).background(RoundedRectangle(cornerRadius: 5).offset(x: 3, y: 3).foregroundColor(color).brightness(-0.3)))
            .font(.system(size: 20, weight: .regular, design: .monospaced))
    }
    
    @ViewBuilder
    private func EndingTime(at date: Date) -> some View {
        if pomoTimer.getStatus(atDate: date) != .end {
            Text("until \(date.addingTimeInterval(pomoTimer.timeRemaining(atDate: date)), formatter: timeFormatter)")
                .font(.system(size: 12, weight: .regular))
                .monospacedDigit()
                .opacity(pomoTimer.isPaused ? 0.5 : 0.8)
        }
    }
    
    @ViewBuilder
    private func StatusIcon(at date: Date) -> some View {
        Text(getIconForStatus(status: pomoTimer.getStatus(atDate: date)))
            .font(.system(size: 14))
    }
    
    @ViewBuilder
    private func TimerView(at date: Date) -> some View {
        Text("\(pomoTimer.timeRemaining(atDate: date).timerFormatted())")
            .accessibilityIdentifier("timeRemaining")
            .font(.system(size: 40, weight: .regular))
            .monospacedDigit()
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
            return Color("End")
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

fileprivate let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
