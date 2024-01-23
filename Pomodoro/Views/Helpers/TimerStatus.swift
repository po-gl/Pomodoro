//
//  TimerStatus.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/22/24.
//

import SwiftUI

struct TimerStatus: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var pomoTimer: PomoTimer

    var body: some View {
        let status = pomoTimer.status
        if !pomoTimer.isPaused || status == .end {
            Button(action: {
                NotificationCenter.default.post(name: .selectFirstTab, object: nil)
            }) {
                Text(status.rawValue)
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(status.color)
                    .brightness(colorScheme == .dark ? 0.2 : 0.05)
                    .saturation(0.8)
                    .brightness(colorScheme == .light && status == .end ? -0.15 : 0.0)
            }
        }
    }
}

#Preview {
    TimerStatus()
        .environmentObject(PomoTimer())
}
