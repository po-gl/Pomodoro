//
//  ProgressBar.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/22.
//

import Foundation
import SwiftUI

struct ProgressBar: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var pomoTimer: PomoTimer
    
    var metrics: GeometryProxy
    
    private let barOutlinePadding: Double = 2.0
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack (spacing: 0) {
                HStack {
                    Text("progress")
                        .font(.system(size: 15, design: .monospaced))
                    Spacer()
                    Text("\(Int(getTimerProgress(atDate: context.date) * 100))%")
                        .font(.system(size: 15, design: .monospaced))
                }
                .padding(.bottom, 8)
                
                ZStack {
                    colorBars()
                    if getTimerProgress(atDate: context.date) != 0.0 || !pomoTimer.isPaused {
                        progressIndicator(at: context.date)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, barOutlinePadding)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(colorScheme == .dark ? .black : .black)
                }
            }
            .padding(.horizontal)
        }
    }
    
    
    func getTimerProgress(atDate: Date = Date()) -> TimeInterval {
        let index = pomoTimer.getIndex(atDate: atDate)
        let intervals = pomoTimer.order.map { $0.getTime() }
        let total = intervals.reduce(0, +)
        var cumulative = 0.0
        for i in 0..<index {
           cumulative += intervals[i]
        }
        let currentTime = intervals[index] - floor(pomoTimer.timeRemaining(atDate: atDate))
        let progress = (cumulative + currentTime) / total
        return progress <= 1.0 ? progress : 1.0
    }
    
    func getProportion(_ index: Int) -> Double {
        let intervals = pomoTimer.order.map { $0.getTime() }
        let total = intervals.reduce(0, +)
        return intervals[index] / total
    }
    
    
    func getColorForStatus(_ status: PomoStatus) -> Color {
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
    
    
    func getBarWidth() -> Double {
        return metrics.size.width - 32.0 - barOutlinePadding*2
    }
    
    
    func colorBars() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundColor(getColorForStatus(pomoTimer.order[i].getStatus()))
                        .frame(width: getBarWidth() * getProportion(i) - 2, height: 16)
                        .padding(.horizontal, 1)
                }
            }
        }
    }
    
    func progressIndicator(at date: Date) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Rectangle()
                .foregroundColor(colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.35))
                .blendMode(colorScheme == .dark ? .colorBurn : .colorDodge)
                .frame(width: getBarWidth() * (1 - getTimerProgress(atDate: date)), height: 16)
        }.mask {
            colorBars()
        }
    }
}
