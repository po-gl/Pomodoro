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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject var pomoTimer: PomoTimer

    let startStopAnimation: Animation = .interpolatingSpring(stiffness: 190, damping: 13)

    var body: some View {
        ZStack {
            TimelineView(PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)) { context in
                VStack(alignment: .center, spacing: 0) {
                    // TOP
                    HStack(alignment: .bottom, spacing: 0) {
                        statusBox(at: context.date)
                            .padding(.trailing, 8)
                        endingTime(at: context.date)
                            .offset(y: -5)
                        Spacer(minLength: 0)
                    }
                    .offset(x: 10)

                    // MIDDLE
                    timerView(at: context.date)

                    // BOTTOM
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        currentPomoView(at: context.date)
                            .offset(y: -5)
                    }
                    .offset(x: -10)
                }
                .frame(width: 300, height: 160)
                .animation(.easeInOut(duration: 0.2), value: pomoTimer.getStatus(atDate: context.date))

            }
        }
        .drawingGroup()
        .offset(y: pomoTimer.isPaused ? 0 : 10)
        .animation(startStopAnimation, value: pomoTimer.isPaused)
    }

    @ViewBuilder
    private func statusBox(at date: Date) -> some View {
        let color = pomoTimer.getStatus(atDate: date).color
        let fgColor = colorScheme == .dark ? color : .black
        let bgColor = colorScheme == .dark ? .black : color
        let text = if pomoTimer.getStatus(atDate: date) == .longBreak && isLargerDynamicFont {
            "Break"
        } else {
            pomoTimer.getStatusString(atDate: date)
        }
        Text(text)
            .font(.system(.title, design: .rounded, weight: .semibold))
            .foregroundColor(fgColor)
            .brightness(colorScheme == .dark ? 0.1 : 0.0)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(bgColor)
                    .brightness(colorScheme == .dark ? 0.0 : 0.05)
                    .shadow(radius: 2, x: 2, y: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .offset(x: 3, y: 3)
                            .foregroundColor(bgColor).brightness(-0.3)))
    }

    @ViewBuilder
    private func endingTime(at date: Date) -> some View {
        let color = colorScheme == .dark ? pomoTimer.getStatus(atDate: date).color : .white
        Text("until \(date.addingTimeInterval(pomoTimer.timeRemaining(atDate: date)), formatter: timeFormatter)")
            .colorScheme(colorScheme == .dark ? .light : .dark)
            .font(.system(.headline, design: .rounded, weight: .medium))
            .monospacedDigit()
            .foregroundColor(color)
            .brightness(colorScheme == .dark ? -0.45 : -0.5)
            .brightness(pomoTimer.isPaused ? 0.0 : (colorScheme == .dark ? -0.2 : 0.3))
    }

    @ViewBuilder
    private func timerView(at date: Date) -> some View {
        Text(pomoTimer.timeRemaining(atDate: date).timerFormatted())
            .font(.system(size: 70,
                          weight: pomoTimer.isPaused ? .light : .regular,
                          design: .rounded))
            .monospacedDigit()
            .colorScheme(colorScheme == .dark ? .light : .dark)
    }

    @ViewBuilder
    private func currentPomoView(at date: Date) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.pomoCount, id: \.self) { i in
                let status = pomoTimer.getStatus(atDate: date)
                let isBreakOrEnd = status == .longBreak || status == .end
                Text("🍅")
                    .font(.title2)
                    .opacity(pomoTimer.currentPomo(atDate: date) <= i+1 && !isBreakOrEnd ? 1.0 : 0.3)
                    .background(
                        Text("🍅")
                            .font(.title2)
                            .scaleEffect(1.0)
                            .brightness(-1.0).opacity(colorScheme == .dark ? 1.0 : 0.0))
                    .brightness(colorScheme == .dark ? -0.1 : 0.0)
            }
        }
    }

    private var isLargerDynamicFont: Bool {
        if dynamicTypeSize.isAccessibilitySize {
            return true
        }
        switch dynamicTypeSize {
        case .xxLarge, .xxxLarge:
            return true
        default:
            return false
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
