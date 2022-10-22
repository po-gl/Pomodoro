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
    
    @State var colorBarIndicatorProgress = 0.0
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            downIndicator()
                .offset(x: getBarWidth() * colorBarIndicatorProgress)
            ZStack {
                HStack(spacing: 0) {
                    ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                        ZStack {
                            Rectangle()
                                .foregroundColor(getColorForStatus(pomoTimer.order[i].getStatus()))
                                .frame(width: getBarWidth() * getProportion(i), height: 16)
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(width: getBarWidth() * getProportion(i) - 2.0, height: 16)
                                Rectangle()
                                    .frame(width: 2, height: 16)
                            }
                        }
                    }
                }
                startEdge()
                lowerEdge()
            }
            upIndicator()
                .offset(x: getBarWidth() * colorBarIndicatorProgress)
        }
        .onChange(of: pomoTimer.timeRemaining) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                colorBarIndicatorProgress = getTimerProgress()
            }
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
        }
    }
    
    
    func getBarWidth() -> Double {
        return metrics.size.width - 32.0
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
    
    func startEdge() -> some View {
        return Rectangle()
            .foregroundColor(.clear)
            .background(LinearGradient(gradient: Gradient(colors: [.black, .gray]), startPoint: .top, endPoint: .bottom))
            .frame(width: 2, height: 30)
            .offset(x:  -getBarWidth()/2.0 - 1.0, y: 1.0)
    }
    
    func lowerEdge() -> some View {
        return Rectangle()
            .frame(width: getBarWidth(), height: 2)
            .offset(y: 8)
    }
}
