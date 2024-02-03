//
//  DynamicIslandProgressView.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/9/23.
//

#if canImport(ActivityKit)
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct DynamicIslandProgressView: View {
    let context: ActivityViewContext<PomoAttributes>

    let status: PomoStatus

    
    let timerInterval: ClosedRange<Date>

    let pausedAt: Date?

    var body: some View {
        if let pausedAt {
            ProgressView(value: pausedAt.progressBetween(timerInterval.lowerBound, timerInterval.upperBound), label: {}, currentValueLabel: {
                Text(Image(systemName: "leaf.fill"))
                    .foregroundColor(Color(hex: 0x31E377))
                    .fontWeight(.bold)
                    .saturation(0.6)
                    .scaleEffect(0.8)
            })
            .progressViewStyle(.circular)
            .tint(status.color)
            .brightness(0.4)
        } else {
            ProgressView(timerInterval: timerInterval, label: {}, currentValueLabel: {
                Text(status.icon)
                    .foregroundStyle(status.color)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
            })
            .progressViewStyle(.circular)
            .tint(status.color)
            .brightness(0.4)
        }
    }
}
#endif
