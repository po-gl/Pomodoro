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
        var currentPomo: Int
        var pomoCount: Int
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
        VStack {
            HStack(spacing: 10) {
                pauseButton()
                tomatoFiller()
                Spacer()
                VStack(alignment: .trailing) {
                    timerView()
                    HStack(spacing: 4) {
                        statusView()
                        timerEndView()
                    }
                    pomoView()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .activitySystemActionForegroundColor(.white.opacity(0.8))
        .activityBackgroundTint(.black.opacity(0.8))
    }
    
    
    private func pauseButton() -> some View {
        Link(destination: URL(string: "com.po-gl.stop")!) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(Color("AccentColor"))
                .font(.system(size: 56))
                .frame(width: 50)
        }
    }
    
    private func tomatoFiller() -> some View {
        Text("🍅")
            .font(.system(size: 34))
            .padding(10)
            .background(Circle().foregroundColor(.black).opacity(0.2))
    }
    
    private func timerView() -> some View {
        Text(timerInterval: context.state.timer, countsDown: true)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 42, weight: .light))
            .monospacedDigit()
    }
    
    private func statusView() -> some View {
        Text("\(context.state.status.rawValue)")
            .font(.system(size: 20, weight: .thin, design: .serif))
            .foregroundColor(.black)
            .padding(.horizontal, 5)
            .background(Rectangle().foregroundColor(getColorForStatus(context.state.status)))
    }
    
    private func timerEndView() -> some View {
        Text("until \(context.state.timer.upperBound, formatter: timeFormatter)")
            .font(.system(size: 17, weight: .regular, design: .serif))
            .monospacedDigit()
            .opacity(0.5)
    }
    
    private func pomoView() -> some View {
        Text("Pomo \(context.state.currentPomo)/\(context.state.pomoCount)")
            .font(.system(size: 17, weight: .thin, design: .serif))
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
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("hh:mm")
        return formatter
    }()
}
