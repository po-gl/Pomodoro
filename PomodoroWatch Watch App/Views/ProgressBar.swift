//
//  ProgressBar.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import SwiftUI

struct ProgressBar: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var metrics: GeometryProxy
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack (alignment: .leading, spacing: 0) {
                if context.cadence == .live {
                    downIndicator()
                        .offset(x: getBarWidth() * getTimerProgress(atDate: context.date))
                } else {
                    Spacer(minLength: 6)
                }
                ZStack {
                    HStack(spacing: 0) {
                        ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                            ZStack {
                                Rectangle()
                                    .foregroundColor(getColorForStatus(pomoTimer.order[i].getStatus()))
                                    .frame(width: getBarWidth() * getProportion(i), height: 6)
                                
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .frame(width: getBarWidth() * getProportion(i) - 1.0, height: 6)
                                    Rectangle()
                                        .frame(width: 1, height: 6)
                                }
                            }
                        }
                    }
                    startEdge()
                }
                if context.cadence == .live {
                    upIndicator()
                        .offset(x: getBarWidth() * getTimerProgress(atDate: context.date))
                } else {
                    Spacer(minLength: 6)
                }
            }
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
        return metrics.size.width - 32.0
    }
    
    
    func downIndicator() -> some View {
        return Rectangle()
            .foregroundColor(.primary)
            .frame(width: 2, height: 6)
            .offset(x: -2, y: -2)
    }
    
    func upIndicator() -> some View {
        return Rectangle()
            .foregroundColor(.secondary)
            .frame(width: 2, height: 6)
            .offset(x: -2, y: 2)
    }
    
    func startEdge() -> some View {
        return Rectangle()
            .foregroundColor(.clear)
            .background(LinearGradient(gradient: Gradient(colors: [.primary, .secondary]), startPoint: .top, endPoint: .bottom))
            .frame(width: 2, height: 12)
            .offset(x:  -getBarWidth()/2.0 - 1.0, y: 0.0)
    }
    
    func lowerEdge() -> some View {
        return Rectangle()
            .frame(width: getBarWidth(), height: 1)
            .offset(y: 4)
    }
}
