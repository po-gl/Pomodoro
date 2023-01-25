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
    public typealias LivePomoState = ContentState
    
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var status: PomoStatus
        var timer: ClosedRange<Date>
    }

    // Fixed non-changing properties about your activity go here!
//    var name: String
}

@available(iOS 16.1, *)
struct iOSWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
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
        VStack(alignment: .trailing) {
            HStack(alignment: .bottom, spacing: 0) {
                HStack(spacing: 0) {
                    Link(destination: URL(string: "com.po-gl.stop")!) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 44))
                            .scaleEffect(1.1)
                            .frame(width: 50)
                            .padding(.leading).padding(.vertical)
                            .padding(.trailing, 8)
                    }
//                    Text("\(getIcon(for: context.state.status))")
                    Text("🍅")
                        .font(.system(size: 26))
                        .padding(10)
                        .background(Circle().foregroundColor(.black).opacity(0.2))
                }
                Spacer()
                HStack {
                    Text("\(context.state.status.rawValue)")
                        .font(.system(size: 20, weight: .thin, design: .serif))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .background(Rectangle().foregroundColor(getColorForStatus(context.state.status)))
                        .offset(y: 3)
                    Text(timerInterval: context.state.timer, countsDown: true)
                        .foregroundColor(getColorForStatus(context.state.status))
                        .font(.system(size: 42, weight: .light))
                        .frame(width: 120, alignment: .trailing)
                        .monospacedDigit()
                }
                .padding(.trailing)
                .padding(.bottom)
            }
        }
        .activitySystemActionForegroundColor(.white.opacity(0.8))
        .activityBackgroundTint(.black.opacity(0.8))
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
            return .accentColor
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
