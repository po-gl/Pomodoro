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
    @EnvironmentObject var pomoTimer: PomoTimer

    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)) { context in
            VStack {
                HStack {
                    Spacer()
                    taskListButton(at: context.date)
                }
                .padding(.top, 20)
                .padding(.trailing, 40)
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: pomoTimer.getStatus())
        }
    }

    @ViewBuilder
    private func taskListButton(at date: Date) -> some View {
        let status = pomoTimer.getStatus(atDate: date)
        let backgroundColor = colorScheme == .dark ? .black : status.color
        let foregroundColor = colorScheme == .dark ? status.color : .black

        NavigationLink(destination: destination) {
            Image(systemName: "checklist")
                .padding(.vertical, 5)
                .padding(.horizontal, 12)
                .foregroundStyle(foregroundColor)
                .background(RoundedRectangle(cornerRadius: 30)
                    .foregroundStyle(backgroundColor).shadow(radius: 2, x: 1, y: 1)
                    .background(RoundedRectangle(cornerRadius: 30)
                        .offset(x: 2.5, y: 2.5)
                        .foregroundStyle(backgroundColor).brightness(-0.3)))
        }
    }
}
