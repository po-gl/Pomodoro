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

    var metrics: GeometryProxy

    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            if #available(watchOS 10, *) {
                MainDisplay(at: context.date)
                    .containerBackground(getColorForStatus(pomoTimer.getStatus(atDate: context.date)).gradient.opacity(0.4), for: .tabView)
            } else {
                MainDisplay(at: context.date)
            }
        }
    }

    @ViewBuilder
    private func MainDisplay(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                StatusBox(at: date)
                Spacer()
                EndingTime(at: date)
                    .offset(x: 4, y: 5)
            }
            .frame(width: metrics.size.width - 20)
            TimerView(at: date)
        }
    }

    @ViewBuilder
    private func StatusBox(at date: Date) -> some View {
        let color = isLuminanceReduced ? .black : getColorForStatus(pomoTimer.getStatus(atDate: date))

        Text(getStringForStatus(pomoTimer.getStatus(atDate: date)))
            .accessibilityIdentifier("statusString")
            .foregroundColor(isLuminanceReduced ? getColorForStatus(pomoTimer.getStatus(atDate: date)) : .black)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 5).foregroundColor(color)
                    .shadow(radius: 2, x: 2, y: 2)
                    .background(RoundedRectangle(cornerRadius: 5).offset(x: 3, y: 3).foregroundColor(color).brightness(-0.3))
            )
            .font(.system(size: 24, weight: .medium, design: .serif))
    }

    @ViewBuilder
    private func EndingTime(at date: Date) -> some View {
        if pomoTimer.getStatus(atDate: date) != .end {
            HStack(alignment: .bottom, spacing: 2) {
                Text("until")
                    .font(.footnote)
                    .offset(y: -1)
                Text("\(date.addingTimeInterval(pomoTimer.timeRemaining(atDate: date)), formatter: timeFormatter)")
                    .font(.body)
            }
            .monospacedDigit()
            .opacity(pomoTimer.isPaused ? 0.5 : 0.8)
        }
    }

    @ViewBuilder
    private func TimerView(at date: Date) -> some View {
        Text(pomoTimer.timeRemaining(atDate: date).timerFormatted())
            .accessibilityIdentifier("timeRemaining")
            .font(.system(size: 40, weight: .medium, design: .rounded))
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

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    formatter.amSymbol = ""
    formatter.pmSymbol = ""
    return formatter
}()
