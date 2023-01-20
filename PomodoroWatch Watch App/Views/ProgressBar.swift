//
//  ProgressBar.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import SwiftUI

struct ProgressBar: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @ObservedObject var pomoTimer: PomoTimer
    
    var metrics: GeometryProxy
    
    @State var scrollValue = 0.0
    @State var isScrolling = false
    
    private let barOutlinePadding: Double = 2.0
    private let barHeight: Double = 8.0
    
    var body: some View {
        scrollableTimeLineColorBars()
    }
    
    func scrollableTimeLineColorBars() -> some View {
        timeLineColorBars()
            .focusable(pomoTimer.isPaused)
            .digitalCrownRotation($scrollValue, from: 0.0, through: 100,
                                  sensitivity: .medium,
                                  isHapticFeedbackEnabled: true,
                                  onChange: { event in
                guard event.velocity != 0.0 else { return }
                isScrolling = true
                pomoTimer.setPercentage(to: event.offset.rounded() / 100)
            })
            .onChange(of: pomoTimer.isPaused) { _ in
                isScrolling = false
                scrollValue = pomoTimer.getCurrentPercentage() * 100.0
            }
            .onChange(of: pomoTimer.getStatus()) { _ in
                if isScrolling {
                    basicHaptic()
                }
            }
    }
    
    func timeLineColorBars() -> some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("\(Int(getTimerProgress(atDate: context.date) * 100))%")
                        .font(.system(size: 14, design: .monospaced))
                }
                .padding(.bottom, 3)
                .padding(.horizontal, 15)
                
                ZStack {
                    colorBars()
                    if getTimerProgress(atDate: context.date) != 0.0 || !pomoTimer.isPaused {
                        progressIndicator(at: context.date)
                    }
                }
                .padding(.horizontal, 10)
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
    
    func getGradientForStatus(_ status: PomoStatus) -> LinearGradient {
        switch status {
        case .work:
            return LinearGradient(stops: [.init(color: Color("BarWork"), location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        case .rest:
            return LinearGradient(stops: [.init(color: Color("BarRest"), location: 0.2),
                                          .init(color: Color(hex: 0xE8BEB1), location: 1.0)],
                                  startPoint: .leading, endPoint: .trailing)
        case .longBreak:
            return LinearGradient(stops: [.init(color: Color("BarLongBreak"), location: 0.5),
                                          .init(color: Color(hex: 0xF5E1E1), location: 1.3)],
                                  startPoint: .leading, endPoint: .trailing)
        case .end:
            return LinearGradient(stops: [.init(color: Color("End"), location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        }
    }
    
    
    func getBarWidth() -> Double {
        return metrics.size.width - 20.0
    }
    
    func colorBars() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .foregroundStyle(getGradientForStatus(pomoTimer.order[i].getStatus()))
                        .frame(width: getBarWidth() * getProportion(i) - 2, height: barHeight)
                        .padding(.horizontal, 1)
                }
            }
        }
    }
    
    func progressIndicator(at date: Date) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Rectangle()
                .foregroundColor(.black.opacity(0.5))
                .blendMode(.colorBurn)
                .frame(width: getBarWidth() * (1 - getTimerProgress(atDate: date)), height: barHeight)
        }.mask {
            colorBars()
        }
    }
}
