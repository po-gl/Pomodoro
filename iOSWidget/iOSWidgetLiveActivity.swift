//
//  iOSWidgetLiveActivity.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PomoAttributes: ActivityAttributes {
    public typealias PomoState = ContentState

    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var status: String
        var task: String
        var startTimestamp: TimeInterval

        var currentSegment: Int
        var segmentCount: Int

        var timeRemaining: TimeInterval
        var isFullSegment: Bool

        var isPaused: Bool
    }
    // Fixed non-changing properties about your activity go here!
}

@available(iOS 16.1, *)
struct iOSWidgetLiveActivity: Widget {
// swiftlint:disable:previous type_name
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { _ in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("Min")
            }
            .keylineTint(Color.red)
        }
    }
}

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PomoAttributes>

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
                                  segmentCount: context.state.segmentCount - 1) // -1 to take off end segment
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .activitySystemActionForegroundColor(.white.opacity(0.8))
        .activityBackgroundTint(.black.opacity(0.7))
        .task {
            if context.state.isFullSegment, let notification = await UNUserNotificationCenter.current().pendingNotificationRequests().first {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notification.identifier])
            }
        }
    }
    
    var status: PomoStatus {
        switch context.state.status.lowercased() {
        case "work":
            return .work
        case "rest":
            return .rest
        case "long break":
            return .longBreak
        case "finished":
            return .end
        default:
            return .end
        }
    }
    
    var startDate: Date {
        Date(timeIntervalSince1970: context.state.startTimestamp)
    }

    var segmentStartDate: Date {
        if context.state.isFullSegment {
            return startDate
        }
        switch status {
        case .work:
            return endDate.addingTimeInterval(-PomoTimer.defaultWorkTime)
        case .rest:
            return endDate.addingTimeInterval(-PomoTimer.defaultRestTime)
        case .longBreak:
            return endDate.addingTimeInterval(-PomoTimer.defaultBreakTime)
        case .end:
            return endDate
        }
    }

    var endDate: Date {
        if !context.state.isFullSegment {
            return startDate.addingTimeInterval(context.state.timeRemaining)
        }
        switch status {
        case .work:
            return startDate.addingTimeInterval(PomoTimer.defaultWorkTime)
        case .rest:
            return startDate.addingTimeInterval(PomoTimer.defaultRestTime)
        case .longBreak:
            return startDate.addingTimeInterval(PomoTimer.defaultBreakTime)
        case .end:
            return startDate
        }
    }

    @ViewBuilder var pauseButton: some View {
        let isPaused = context.state.isPaused
        Link(destination: URL(string: isPaused ? "com.po-gl.unpause" : "com.po-gl.pause")!) {
            Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                .foregroundStyle(getGradientForStatus(status))
                .opacity(0.8)
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
        let color = getColorForStatus(status)
        let task = context.state.task
        Text(task != "" ? task : status.rawValue)
            .font(.system(.headline, design: .rounded, weight: .light))
            .lineLimit(1)
            .foregroundStyle(.black)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(color)
                    .brightness(0.1)
                    .shadow(radius: 2, x: 2, y: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .offset(x: 3, y: 3)
                            .foregroundStyle(color)
                            .brightness(-0.3)
                    )
            )
    }

    @ViewBuilder var timerEndView: some View {
        Text("until \(endDate, formatter: timeFormatter)")
            .font(.system(.subheadline, design: .rounded, weight: .regular))
            .monospacedDigit()
            .opacity(0.6)
            .foregroundStyle(.white)
    }

    private func getColorForStatus(_ status: PomoStatus) -> Color {
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

    private func getIcon(for status: PomoStatus) -> String {
        switch status {
        case .work:
            return "🌶️"
        case .rest:
            return "🍇"
        case .longBreak:
            return "🏖️"
        case .end:
            return "🎉"
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
