//
//  TopButton.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/12/23.
//

import SwiftUI

struct TopButton<Destination: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let destination: () -> Destination
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)) { context in
            VStack {
                HStack {
                    Spacer()
                    TaskListButton(at: context.date)
                }
                .padding(.top, 20)
                .padding(.trailing, 40)
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: pomoTimer.getStatus())
        }
    }
    
    @ViewBuilder
    private func TaskListButton(at date: Date) -> some View {
        let status = pomoTimer.getStatus(atDate: date)
        let backgroundColor = colorScheme == .dark ? .black : getColorForStatus(status)
        let foregroundColor = colorScheme == .dark ? getColorForStatus(status) : .black
        
        NavigationLink(destination: destination) {
            Image(systemName: "checklist")
                .frame(width: 50, height: 32)
                .foregroundColor(foregroundColor)
                .background(RoundedRectangle(cornerRadius: 30).foregroundColor(backgroundColor).shadow(radius: 2, x: 1, y: 1).background(RoundedRectangle(cornerRadius: 30).offset(x: 2.5, y: 2.5).foregroundColor(backgroundColor).brightness(-0.3)))
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
}

