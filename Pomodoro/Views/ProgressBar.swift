//
//  ProgressBar.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/22.
//

import Foundation
import SwiftUI

struct ProgressBar: View {
    @ObservedObject var sequenceTimer: SequenceTimer
    @Binding var timeIntervals: [TimeInterval]
    
    var metrics: GeometryProxy
    
    @State var colorBarProportions = [0.666, 0.333]
    @State var colorBarIndicatorProgress = 0.0
    
    
    var body: some View {
        VStack (alignment: .leading) {
            downArrow()
                .offset(x: (metrics.size.width-20) * colorBarIndicatorProgress)
            HStack(spacing: 0) {
                ForEach(0..<timeIntervals.count, id: \.self) { i in
                    ZStack {
                        Rectangle()
                            .foregroundColor(i % 2 == 0 ? Color("BarWork") : Color("BarRest"))
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
        .onChange(of: sequenceTimer.timeRemaining) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                colorBarIndicatorProgress = getTimerProgress()
            }
        }
        .onAppear() {
            updateProportions()
        }
    }
    
    
    func getTimerProgress() -> TimeInterval {
        let intervals = sequenceTimer.sequenceOfIntervals
        let total = intervals.reduce(0, +)
        var cumulative = 0.0
        for i in 0..<sequenceTimer.currentIndex {
           cumulative += intervals[i]
        }
        let currentTime = intervals[sequenceTimer.currentIndex] - sequenceTimer.timeRemaining
        return (cumulative + currentTime) / total
    }
    
    
    func updateProportions() {
        let intervals = timeIntervals
        let total = intervals.reduce(0, +)
        for i in 0..<intervals.count {
            colorBarProportions[i] = intervals[i] / total
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
}
