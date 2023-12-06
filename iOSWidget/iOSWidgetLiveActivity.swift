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
        
        var timeRemaining: TimeInterval
        var isFirst: Bool
    }

    // Fixed non-changing properties about your activity go here!
    var segmentCount: Int
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
        VStack {
            HStack(spacing: 10) {
                pauseButton
                Text("\(context.state.currentSegment + 1)/\(context.attributes.segmentCount)")
                Spacer()
                VStack(alignment: .trailing) {
                    timerView
                    statusView
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .activitySystemActionForegroundColor(.white.opacity(0.8))
        .activityBackgroundTint(.black.opacity(0.8))
        .task {
            if let notification = await UNUserNotificationCenter.current().pendingNotificationRequests().first {
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

    var endDate: Date {
        if context.state.isFirst {
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
        Link(destination: URL(string: "com.po-gl.stop")!) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(Color("AccentColor"))
                .font(.system(size: 56))
                .frame(width: 50)
        }
    }

    @ViewBuilder var tomatoFiller: some View {
        Text("🍅")
            .font(.system(size: 34))
            .padding(10)
            .background(Circle().foregroundColor(.black).opacity(0.2))
    }

    @ViewBuilder var timerView: some View {
        Text(timerInterval: startDate...endDate, countsDown: true)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 42, weight: .light))
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
    }

    @ViewBuilder var statusView: some View {
        let task = context.state.task
        Text(task != "" ? task : getString(for: status))
            .font(.system(size: 20, weight: .thin, design: .serif))
            .foregroundColor(.black)
            .padding(.horizontal, 5)
            .background(RoundedRectangle(cornerRadius: 8).foregroundColor(getColorForStatus(status)))
    }

    @ViewBuilder var timerEndView: some View {
        Text("until \(endDate, formatter: timeFormatter)")
            .font(.system(size: 17, weight: .regular, design: .serif))
            .monospacedDigit()
            .opacity(0.5)
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

    private func getString(for status: PomoStatus) -> String {
        switch status {
        case .longBreak:
            return "Break"
        default:
            return status.rawValue
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
