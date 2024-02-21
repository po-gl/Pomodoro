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
    @EnvironmentObject var pomoTimer: PomoTimer

    var metrics: GeometryProxy

    @State var scrollValue = 0.0
    @State var isScrolling = false

    private let barOutlinePadding: Double = 2.0
    private let barHeight: Double = 8.0

    private var barWidth: CGFloat {
        metrics.size.width - 20.0
    }

    @State var cachedProportions: [CGFloat]? = nil

    var proportions: [CGFloat] {
        cachedProportions ?? calculateProportions()
    }

    var body: some View {
        VStack(spacing: 3) {
            percentProgress
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 5)
            
            ZStack {
                colorBars
                progressIndicator
            }
        }
        .padding(.horizontal, 10)
        .onAppear {
            cachedProportions = calculateProportions()
        }
        .onChange(of: pomoTimer.order.count) {
            cachedProportions = calculateProportions()
        }
        
        .onChange(of: pomoTimer.workDuration) {
            withAnimation(.bouncy) {
                cachedProportions = calculateProportions()
            }
        }
        .onChange(of: pomoTimer.restDuration) {
            withAnimation(.bouncy) {
                cachedProportions = calculateProportions()
            }
        }
        .onChange(of: pomoTimer.breakDuration) {
            withAnimation(.bouncy) {
                cachedProportions = calculateProportions()
            }
        }

        .focusable(pomoTimer.isPaused)
        .digitalCrownRotation($scrollValue, from: 0.0, through: 100,
                              sensitivity: .medium,
                              isHapticFeedbackEnabled: true,
                              onChange: { event in
            guard event.velocity != 0.0 else { return }
            isScrolling = true
            pomoTimer.setPercentage(to: event.offset.rounded() / 100)
        }, onIdle: {
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation { isScrolling = false }
            }
        })
        .onChange(of: pomoTimer.isPaused) {
            isScrolling = false
            scrollValue = pomoTimer.getCurrentPercentage() * 100.0
        }
        .onChange(of: pomoTimer.status) {
            if isScrolling {
                basicHaptic()
            }
        }
    }

    func calculateProportions() -> [CGFloat] {
        let intervals = pomoTimer.order.map { $0.timeInterval }
        let total = intervals.reduce(0, +)
        let proportions: [CGFloat] = intervals.map { $0 / total }
        let padding: [CGFloat] = Array(repeating: 0.0, count: pomoTimer.maxOrder - proportions.count)
        return proportions + padding
    }

    @ViewBuilder var percentProgress: some View {
        TimelineView(isPausedTimelineSchedule) { context in
            Text("\(Int(pomoTimer.getProgress(atDate: context.date) * 100))%")
                .font(.system(size: 14, design: .monospaced))
        }
    }

    @ViewBuilder var colorBars: some View {
        if proportions.count >= pomoTimer.order.count {
            HStack(spacing: 0) {
                ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                    let width = max(barWidth * proportions[i] - 2.0, 0.0)
                    let barOverlap = 15.0
                    let barOffset = 3.0
                    VStack {
                        RoundedRectangle(cornerRadius: 2.8)
                            .shadow(radius: 4)
                            .scaleEffect(x: 2.0, anchor: .trailing)
                            .foregroundStyle(pomoTimer.order[i].status.gradient())
                            .frame(width: width + barOverlap)
                            .offset(x: -barOverlap / 2 + barOffset)
                            .alignmentGuide(.leading, computeValue: { dimension in
                                dimension[.trailing] - barOverlap
                            })
                    }
                    .frame(width: width, height: barHeight)
                    .padding(.horizontal, 1)
                    .zIndex(Double(pomoTimer.order.count - i))
                }
            }
            .mask { RoundedRectangle(cornerRadius: 5)}
        } else {
            EmptyView()
        }
    }

    @ViewBuilder var progressIndicator: some View {
        TimelineView(isPausedTimelineSchedule) { context in
            let progress = pomoTimer.getProgress(atDate: context.date)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                
                Rectangle()
                    .foregroundStyle(.black.opacity(0.5))
                    .blendMode(.colorBurn)
                    .frame(width: barWidth * (1 - progress), height: barHeight)
                    .overlay {
                        HStack(spacing: 0) {
                            Rectangle().fill(.clear).frame(width: 1, height: barHeight).overlay(
                                AnimatedImage(data: Animations.pickIndicator)
                                    .scaleEffect(40)
                                    .opacity(0.7)
                            )
                            .offset(x: -1)
                            Spacer()
                        }
                    }
            }
            .mask { RoundedRectangle(cornerRadius: 5)}
            .opacity(progress > 0.00001 || !pomoTimer.isPaused || isScrolling ? 1.0 : 0.0)
        }
    }

    var isPausedTimelineSchedule: PeriodicTimelineSchedule {
        PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)
    }
}
