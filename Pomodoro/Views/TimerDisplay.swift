//
//  TimerDisplay.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI


struct TimerDisplay: View {
    @ObservedObject var sequenceTimer: SequenceTimer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(getTimerText(sequenceTimer.currentIndex, sequenceTimer.sequenceOfIntervals.count-1))")
                .font(.system(size: 30))
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
            Text("\(sequenceTimer.timeRemaining.timerFormatted())")
                .font(.system(size: 70))
                .fontWeight(.light)
                .monospacedDigit()
                .shadow(radius: 20)
        }
    }
    
    func getTimerText(_ index: Int, _ last: Int) -> String {
        if index == last {
            return "Long Break"
        }
        return index % 2 == 0 ? "Work" : "Rest"
    }
}
