//
//  TimerDisplay.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI


struct TimerDisplay: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(pomoTimer.statusString)")
                .font(.system(size: 30))
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
            Text("\(pomoTimer.timeRemaining.timerFormatted())")
                .font(.system(size: 70))
                .fontWeight(.light)
                .monospacedDigit()
                .shadow(radius: 20)
        }
    }
}
