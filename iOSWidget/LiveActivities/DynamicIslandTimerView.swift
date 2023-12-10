//
//  DynamicIslandTimerView.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/9/23.
//

import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct DynamicIslandTimerView: View {
    let context: ActivityViewContext<PomoAttributes>

    let status: PomoStatus

    let timerInterval: ClosedRange<Date>
    
    var inExpandedRegion: Bool = false

    var body: some View {
        if context.state.isPaused {
            Text(timerInterval.upperBound.timeIntervalSince(timerInterval.lowerBound).compactTimerFormatted())
                .font(inExpandedRegion ? .largeTitle : .body)
                .fontWeight(.semibold)
                .foregroundStyle(status.color)
                .brightness(0.4)
                .monospacedDigit()
                .frame(maxWidth: inExpandedRegion ? .infinity : status == .rest ? 35 : 45)
        } else {
            // One day Apple might pre-cache view widths as well so a fixed width isn't necessary
            Text(timerInterval: timerInterval, countsDown: true)
                .multilineTextAlignment(.trailing)
                .font(inExpandedRegion ? .system(size: 36) : .body)
                .fontWeight(.semibold)
                .foregroundStyle(status.color)
                .brightness(0.4)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .frame(maxWidth: inExpandedRegion ? .infinity : status == .rest ? 35 : 45)
        }
    }
}
