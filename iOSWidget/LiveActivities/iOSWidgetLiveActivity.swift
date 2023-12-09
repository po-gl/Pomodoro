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
            BannerLiveActivityView(context: context,
                                   status: getStatus(for: context),
                                   startDate: getStartDate(for: context),
                                   endDate: getEndDate(for: context),
                                   segmentStartDate: getSegmentStartDate(for: context))

        } dynamicIsland: { context in
            return DynamicIsland {
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
    
    private func getStatus(for context: ActivityViewContext<PomoAttributes>) -> PomoStatus {
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
    
    private func getStartDate(for context: ActivityViewContext<PomoAttributes>) -> Date {
        Date(timeIntervalSince1970: context.state.startTimestamp)
    }

    private func getSegmentStartDate(for context: ActivityViewContext<PomoAttributes>) -> Date {
        if context.state.isFullSegment {
            return getStartDate(for: context)
        }
        switch getStatus(for: context){
        case .work:
            return getEndDate(for: context).addingTimeInterval(-PomoTimer.defaultWorkTime)
        case .rest:
            return getEndDate(for: context).addingTimeInterval(-PomoTimer.defaultRestTime)
        case .longBreak:
            return getEndDate(for: context).addingTimeInterval(-PomoTimer.defaultBreakTime)
        case .end:
            return getEndDate(for: context)
        }
    }

    private func getEndDate(for context: ActivityViewContext<PomoAttributes>) -> Date {
        if !context.state.isFullSegment {
            return getStartDate(for: context).addingTimeInterval(context.state.timeRemaining)
        }
        switch getStatus(for: context) {
        case .work:
            return getStartDate(for: context).addingTimeInterval(PomoTimer.defaultWorkTime)
        case .rest:
            return getStartDate(for: context).addingTimeInterval(PomoTimer.defaultRestTime)
        case .longBreak:
            return getStartDate(for: context).addingTimeInterval(PomoTimer.defaultBreakTime)
        case .end:
            return getStartDate(for: context)
        }
    }
}

