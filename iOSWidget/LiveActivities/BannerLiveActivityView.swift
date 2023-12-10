//
//  BannerLiveActivityView.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/9/23.
//

import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct BannerLiveActivityView: View {
    let context: ActivityViewContext<PomoAttributes>
    
    let status: PomoStatus
    
    let startDate: Date
    let endDate: Date
    let segmentStartDate: Date

    var body: some View {
        HStack(spacing: 10) {
            pauseButton
            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment:. leading, spacing: 5) {
                        statusView
                        timerEndView
                            .offset(x: 4)
                    }
                    .padding(.top, 4)
                    Spacer()
                    timerView
                }
                WidgetProgressBar(timerInterval: segmentStartDate...endDate,
                                  currentSegment: context.state.currentSegment,
                                  segmentCount: context.state.segmentCount - 1,
                                  pausedAt: context.state.isPaused ? startDate : nil) // -1 to take off end segment
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .activitySystemActionForegroundColor(.white.opacity(0.8))
        .activityBackgroundTint(.black.opacity(0.7))
        .task {
            if let notification = await UNUserNotificationCenter.current().pendingNotificationRequests().first {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notification.identifier])
            }
        }
    }

    @ViewBuilder var pauseButton: some View {
        let isPaused = context.state.isPaused
        Link(destination: URL(string: isPaused ? "com.po-gl.unpause" : "com.po-gl.pause")!) {
            Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                .foregroundStyle(getGradientForStatus(status))
                .opacity(0.8)
                .brightness(0.2)
                .saturation(0.8)
                .font(.system(size: 50))
                .frame(width: 50)
        }
    }

    @ViewBuilder var timerView: some View {
        if context.state.isPaused {
            Text(endDate.timeIntervalSince(startDate).compactTimerFormatted())
                .font(.system(size: 42, weight: .light))
                .monospacedDigit()
                .frame(width: 115, alignment: .trailing)
                .foregroundStyle(.white)
        } else {
            Text(timerInterval: startDate...endDate, countsDown: true)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 42, weight: .light))
                .monospacedDigit()
                .frame(width: 115)
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
        }
    }

    @ViewBuilder var statusView: some View {
        let task = context.state.task
        Text(task != "" ? task : status.rawValue)
            .font(.system(.headline, design: .rounded, weight: .light))
            .lineLimit(1)
            .foregroundStyle(.black)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(status.color)
                    .brightness(0.2)
                    .shadow(radius: 2, x: 2, y: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .offset(x: 3, y: 3)
                            .foregroundStyle(status.color)
                            .brightness(0.0)
                    )
            )
    }

    @ViewBuilder var timerEndView: some View {
        let endTime = context.state.isPaused ? "--:--" : timeFormatter.string(from: endDate)
        Text("until \(endTime)")
            .font(.system(.subheadline, design: .rounded, weight: .regular))
            .monospacedDigit()
            .opacity(0.6)
            .foregroundStyle(.white)
    }

    private func getGradientForStatus(_ status: PomoStatus) -> LinearGradient {
        switch status {
        case .work:
            return LinearGradient(stops: [.init(color: Color("BarWork"), location: 0.7),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.2)],
                                  startPoint: .leading, endPoint: .trailing)
        case .rest:
            return LinearGradient(stops: [.init(color: Color("BarRest"), location: 0.7),
                                          .init(color: Color(hex: 0xE8BEB1), location: 1.2)],
                                  startPoint: .leading, endPoint: .trailing)
        case .longBreak:
            return LinearGradient(stops: [.init(color: Color("BarLongBreak"), location: 0.7),
                                          .init(color: Color(hex: 0xF5E1E1), location: 1.3)],
                                  startPoint: .leading, endPoint: .trailing)
        case .end:
            return LinearGradient(stops: [.init(color: Color("End"), location: 0.7),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.3)],
                                  startPoint: .leading, endPoint: .trailing)
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
