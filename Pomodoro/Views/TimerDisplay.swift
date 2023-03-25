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
            VStack(alignment: .center, spacing: 0) {
                // TOP
                HStack(alignment: .bottom, spacing: 0) {
                    StatusBox(at: context.date)
                        .padding(.trailing, 8)
                    EndingTime(at: context.date)
                        .offset(y: -3)
                    Spacer(minLength: 0)
                }
                .offset(x: 10)
                
                // MIDDLE
                TimerView(at: context.date)
                
                // BOTTOM
                HStack (spacing: 0) {
                    Spacer(minLength: 0)
                    CurrentPomoView(at: context.date)
                        .offset(y: -5)
                }
                .offset(x: -10)
            }
            .frame(width: 300, height: 160)
            .animation(.easeInOut(duration: 0.2), value: pomoTimer.getStatus(atDate: context.date))
        }
    }
    
    @ViewBuilder
    private func StatusBox(at date: Date) -> some View {
        let color = colorScheme == .dark ? .black : getColorForStatus(pomoTimer.getStatus(atDate: date))
        Text(pomoTimer.getStatusString(atDate: date))
            .font(.system(size: 30, weight: .thin, design: .serif))
            .foregroundColor(colorScheme == .dark ? getColorForStatus(pomoTimer.getStatus(atDate: date)) : .black)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 5).foregroundColor(color).background(RoundedRectangle(cornerRadius: 5).offset(x: 3, y: 3).foregroundColor(color).brightness(-0.3)))
    }
    
    @ViewBuilder
    private func EndingTime(at date: Date) -> some View {
        Text("until \(date.addingTimeInterval(pomoTimer.timeRemaining(atDate: date)), formatter: timeFormatter)")
            .colorScheme(colorScheme == .dark ? .light : .dark)
            .font(.system(size: 17, weight: .regular, design: .serif))
            .monospacedDigit()
            .opacity(pomoTimer.isPaused ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private func TimerView(at date: Date) -> some View {
        Text(pomoTimer.timeRemaining(atDate: date).timerFormatted())
            .font(.system(size: 70, weight: .light))
            .monospacedDigit()
            .colorScheme(colorScheme == .dark ? .light : .dark)
    }
    
    @ViewBuilder
    private func CurrentPomoView(at date: Date) -> some View {
        HStack(spacing: 0){
            ForEach(0..<pomoTimer.pomoCount, id: \.self) { i in
                Text("🍅")
                    .font(.system(size: 23))
                    .opacity(pomoTimer.currentPomo(atDate: date) <= i+1 ? 1.0 : 0.3)
                    .background(Text("🍅").font(.system(size: 23)).scaleEffect(1.0).brightness(-1.0).opacity(colorScheme == .dark ? 1.0 : 0.0))
                    .brightness(colorScheme == .dark ? -0.1 : 0.0)
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
            return Color("End")
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("hh:mm")
        return formatter
    }()
}
