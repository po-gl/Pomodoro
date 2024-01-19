//
//  iOSWidgetLiveActivity.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

#if os(iOS)
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
    var workDuration: TimeInterval
    var restDuration: TimeInterval
    var breakDuration: TimeInterval
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
            let status = getStatus(for: context)
            let start = getStartDate(for: context)
            let end = getEndDate(for: context)
            let segmentStart = getSegmentStartDate(for: context)
            return DynamicIsland {
                expandedRegion(for: context, status: status, start: start,
                               end: end, segmentStart: segmentStart)
            } compactLeading: {
                DynamicIslandProgressView(context: context, status: status, timerInterval: segmentStart...end,
                                          pausedAt: context.state.isPaused ? start : nil)
            } compactTrailing: {
                DynamicIslandTimerView(context: context, status: status, timerInterval: start...end)
            } minimal: {
                DynamicIslandProgressView(context: context, status: status, timerInterval: segmentStart...end,
                                          pausedAt: context.state.isPaused ? start : nil)
            }
            .keylineTint(Color.red)
        }
    }
    
    @DynamicIslandExpandedContentBuilder
    private func expandedRegion(for context: ActivityViewContext<PomoAttributes>,
                                status: PomoStatus,
                                start: Date,
                                end: Date,
                                segmentStart: Date) -> DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading, priority: 1.0) {
            Group {
                Group {
                    if context.state.isPaused {
                        Text(Image(systemName: "leaf.fill"))
                            .foregroundColor(Color(hex: 0x31E377))
                            .saturation(0.6)
                            .scaleEffect(0.8)
                    } else {
                        Text(status.icon)
                            .foregroundStyle(status.color)
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .brightness(0.2)
                .offset(x: 4)

                Spacer()

                let task = context.state.task
                Text(task != "" ? task : status.rawValue)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
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
                    .padding(.top, 1)
            }
            .padding(.leading, 2)
        }
        DynamicIslandExpandedRegion(.trailing, priority: 0.0) {
            Group {
                DynamicIslandTimerView(context: context, status: status,
                                       timerInterval: start...end, inExpandedRegion: true)

                let isFinished = context.state.currentSegment == context.state.segmentCount-1
                let endTime = context.state.isPaused || isFinished ? "--:--" : timeFormatter.string(from: end)
                Text("Ends at \(endTime)")
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .monospacedDigit()
                    .opacity(0.6)
                    .offset(x: -3, y: -3)

            }
            .padding(.trailing, 2)
        }
        DynamicIslandExpandedRegion(.bottom) {
            WidgetProgressBar(timerInterval: segmentStart...end,
                              currentSegment: context.state.currentSegment,
                              segmentCount: context.state.segmentCount,
                              pausedAt: context.state.isPaused ? start : nil,
                              workDuration: context.attributes.workDuration,
                              restDuration: context.attributes.restDuration,
                              breakDuration: context.attributes.breakDuration)
            .padding(.horizontal, 3)
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
            return getEndDate(for: context).addingTimeInterval(-context.attributes.workDuration)
        case .rest:
            return getEndDate(for: context).addingTimeInterval(-context.attributes.restDuration)
        case .longBreak:
            return getEndDate(for: context).addingTimeInterval(-context.attributes.breakDuration)
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
            return getStartDate(for: context).addingTimeInterval(context.attributes.workDuration)
        case .rest:
            return getStartDate(for: context).addingTimeInterval(context.attributes.restDuration)
        case .longBreak:
            return getStartDate(for: context).addingTimeInterval(context.attributes.breakDuration)
        case .end:
            return getStartDate(for: context)
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm"
    return formatter
}()
#endif
