//
//  ProgressBar.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/22.
//

import Foundation
import SwiftUI

struct ProgressBar: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var metrics: GeometryProxy
    
    @State var colorBarProportions: [Double] = []
    @State var colorBarIndicatorProgress = 0.0
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            downIndicator()
                .offset(x: getBarWidth() * colorBarIndicatorProgress)
            ZStack {
                HStack(spacing: 0) {
                    ForEach(0..<colorBarProportions.count, id: \.self) { i in
                        ZStack {
                            Rectangle()
                                .foregroundColor(getColorForStatus(pomoTimer.order[i].getStatus()))
                                .frame(width: getBarWidth() * colorBarProportions[i], height: 16)
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(width: getBarWidth() * colorBarProportions[i] - 2.0, height: 16)
                                Rectangle()
                                    .frame(width: 2, height: 16)
                            }
                        }
                    }
                }
                Rectangle()
                    .frame(width: 2, height: 30)
                    .offset(x:  -getBarWidth()/2.0 - 1.0, y: 1.0)
                Rectangle()
                    .frame(width: getBarWidth(), height: 2)
                    .offset(y: 8)
            }
            upIndicator()
                .offset(x: getBarWidth() * colorBarIndicatorProgress)
        }
        .onChange(of: pomoTimer.timeRemaining) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                colorBarIndicatorProgress = getTimerProgress()
            }
        }
        .onAppear() {
            updateProportions()
        }
    }
    
    
    func getTimerProgress() -> TimeInterval {
        let intervals = pomoTimer.order.map { $0.getTime() }
        let total = intervals.reduce(0, +)
        var cumulative = 0.0
        for i in 0..<pomoTimer.currentIndex {
           cumulative += intervals[i]
        }
        let currentTime = intervals[pomoTimer.currentIndex] - pomoTimer.timeRemaining
        return (cumulative + currentTime) / total
    }
    
    
    func updateProportions() {
        colorBarProportions.removeAll()
        let intervals = pomoTimer.order.map { $0.getTime() }
        let total = intervals.reduce(0, +)
        for interval in intervals {
            colorBarProportions.append(interval / total)
        }
    }
    
    
    func downIndicator() -> some View {
        return Rectangle()
            .frame(width: 2, height: 16)
            .offset(x: -2, y: -2)
    }
    
    func upIndicator() -> some View {
        return Rectangle()
            .foregroundColor(.gray)
            .frame(width: 2, height: 16)
            .offset(x: -2, y: 4)
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
    
    func getBarWidth() -> Double {
        return metrics.size.width - 32.0
    }
}
