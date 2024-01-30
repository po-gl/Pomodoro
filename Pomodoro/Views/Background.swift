//
//  Background.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/19/23.
//

import SwiftUI

struct Background: View {
    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject var pomoTimer: PomoTimer

    var pickOffset = CGFloat.zero
    /// Workaround due to metal views not updating for Transaction-based SwiftUI animations
    var metalPickOffset = CGFloat.zero

    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)) { context in
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    top(at: context.date)
                        .frame(height: getTopFrameHeight(proxy: geometry))
                    BackgroundDivider(metalPickOffset: metalPickOffset).zIndex(2)
                        .verticalOffsetEffect(for: pickOffset, .spring, factor: 0.14)
                    bottom(at: context.date, geometry: geometry)
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: pomoTimer.getStatus(atDate: context.date))
            }
        }
    }

    @ViewBuilder
    private func top(at date: Date) -> some View {
        if colorScheme == .dark {
            Rectangle()
                .foregroundColor(getTopColor(at: date))
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
                        .blendMode(.softLight)
                )
                .brightness(0.1)
                .drawingGroup()
        } else {
            Rectangle()
                .foregroundColor(getTopColor(at: date))
        }
    }

    @ViewBuilder
    private func bottom(at date: Date, geometry: GeometryProxy) -> some View {
        Rectangle()
            .foregroundColor(getBottomColor(at: date))
            .overlay(
                Rectangle()
                    .fill(LinearGradient(colors: [colorScheme == .light ? .white : .clear, .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .opacity(0.6)
                    .blendMode(.softLight)
                    // SwiftUI bug: blendmode flickers to normal if touching
                    // edges during navigation animations
                    .frame(maxWidth: max(geometry.size.width - 2, 0))
            )
    }

    private func getBottomColor(at date: Date) -> Color {
        if colorScheme == .dark {
            return .black
        } else if pomoTimer.isPaused {
            return Color(.backgroundStopped)
        }

        switch pomoTimer.getStatus(atDate: date) {
        case .work:
            return Color(.backgroundWork)
        case .rest:
            return Color(.backgroundRest)
        case .longBreak:
            return Color(.backgroundLongBreak)
        case .end:
            return Color(.backgroundStopped)
        }
    }

    private func getTopColor(at date: Date) -> Color {
        if colorScheme == .light {
            .black
        } else {
            pomoTimer.getStatus(atDate: date).color
        }
    }

    private func getTopFrameHeight(proxy: GeometryProxy) -> Double {
        let height = proxy.size.height / 2.5 + (colorScheme == .dark ? 30.0 : -35.0)
        return max(height, 0)
    }
}
