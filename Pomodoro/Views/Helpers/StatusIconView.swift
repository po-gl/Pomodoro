//
//  StatusIconView.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/16/23.
//

import SwiftUI

struct StatusIconView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            ZStack {
                let color = colorScheme == .dark ? .black : getColorForStatus(pomoTimer.getStatus(atDate: context.date))
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 14).fill(color).offset(x: 2, y: 2).brightness(-0.3))
                Text("\(getIconForStatus(status: pomoTimer.getStatus(atDate: context.date)))")
                    .font(.system(size: 15))
            }
            .animation(.easeInOut(duration: 0.2), value: pomoTimer.getStatus(atDate: context.date))
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
}
