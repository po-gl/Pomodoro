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

    var body: some View {
        ScrollableTimeLineColorBars
    }

    @ViewBuilder private var ScrollableTimeLineColorBars: some View {
        TimeLineColorBars
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

    @ViewBuilder private var TimeLineColorBars: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("\(Int(pomoTimer.getProgress(atDate: context.date) * 100))%")
                        .font(.system(size: 14, design: .monospaced))
                }
                .padding(.bottom, 3)
                .padding(.horizontal, 15)

                ZStack {
                    ColorBars
                        .mask { RoundedRectangle(cornerRadius: 5)}
                    ProgressIndicator(at: context.date)
                        .opacity(shouldShowProgressIndicator(at: context.date) ? 1.0 : 0.0)
                }
                .padding(.horizontal, 10)
            }
        }
    }

    private func shouldShowProgressIndicator(at date: Date) -> Bool {
        return pomoTimer.getProgress(atDate: date) != 0.0 || !pomoTimer.isPaused || isScrolling
    }

    private func getProportion(_ index: Int) -> Double {
        let intervals = pomoTimer.order.map { $0.timeInterval }
        let total = intervals.reduce(0, +)
        return intervals[index] / total
    }

    private func getGradient(for status: PomoStatus) -> LinearGradient {
        switch status {
        case .work:
            return LinearGradient(stops: [.init(color: .barWork, location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        case .rest:
            return LinearGradient(stops: [.init(color: .barRest, location: 0.2),
                                          .init(color: Color(hex: 0xE8BEB1), location: 1.0)],
                                  startPoint: .leading, endPoint: .trailing)
        case .longBreak:
            return LinearGradient(stops: [.init(color: .barLongBreak, location: 0.5),
                                          .init(color: Color(hex: 0xF5E1E1), location: 1.3)],
                                  startPoint: .leading, endPoint: .trailing)
        case .end:
            return LinearGradient(stops: [.init(color: .end, location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        }
    }

    private func getBarWidth() -> Double {
        return metrics.size.width - 20.0
    }

    @ViewBuilder private var ColorBars: some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .scaleEffect(x: 2.0, anchor: .trailing)
                    .foregroundStyle(getGradient(for: pomoTimer.order[i].status))
                    .frame(width: getBarWidth() * getProportion(i) - 2, height: barHeight)
                    .padding(.horizontal, 1)
                    .zIndex(Double(pomoTimer.order.count - i))
                    .shadow(radius: 4)
            }
        }
    }

    @ViewBuilder
    private func ProgressIndicator(at date: Date) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            Rectangle()
                .foregroundColor(.black.opacity(0.5))
                .blendMode(.colorBurn)
                .frame(width: getBarWidth() * (1 - pomoTimer.getProgress(atDate: date)), height: barHeight)
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
    }
}
