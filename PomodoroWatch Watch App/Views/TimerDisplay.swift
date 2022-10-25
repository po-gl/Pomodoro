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
        VStack(alignment: .leading) {
            Text("\(pomoTimer.statusString)")
                .foregroundColor(getColorForStatus(pomoTimer.status))
                .font(.system(size: 26))
                .fontWeight(.light)
            Text("\(pomoTimer.timeRemaining.timerFormatted())")
                .font(.system(size: 40))
                .fontWeight(.regular)
                .monospacedDigit()
                .shadow(radius: 20)
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
        }
    }
}
