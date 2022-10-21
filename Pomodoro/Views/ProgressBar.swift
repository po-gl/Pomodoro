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
        VStack (alignment: .leading) {
            downArrow()
                .offset(x: (metrics.size.width-20) * colorBarIndicatorProgress)
            HStack(spacing: 0) {
                ForEach(0..<colorBarProportions.count, id: \.self) { i in
                    ZStack {
                        Rectangle()
                            .foregroundColor(getColorForStatus(pomoTimer.order[i].getStatus()))
                            .innerShadow(using: Rectangle())
                            .cornerRadius(10)
                            .padding(.horizontal, 2)
                    }
                        .frame(maxWidth: metrics.size.width * colorBarProportions[i], maxHeight: 80)
                }
            }
            upArrow()
                .offset(x: (metrics.size.width-20) * colorBarIndicatorProgress)
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
    
    
    func downArrow() -> some View {
        return Image(systemName: "arrowtriangle.down.fill")
            .imageScale(.large)
            .foregroundColor(Color(hex: 0x444444))
            .opacity(0.9)
    }
    
    func upArrow() -> some View {
        return Image(systemName: "arrowtriangle.up.fill")
            .imageScale(.large)
            .foregroundColor(Color(hex: 0xAAAAAA))
            .opacity(0.7)
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
