//
//  iOSWidget.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

import WidgetKit
import SwiftUI

struct iOSWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: true)) { entry in
            iOSWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct iOSWidgetView: View {
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        if #available(iOSApplicationExtension 17, *) {
            content
                .containerBackground(for: .widget) {
                    Color.black
                }
        } else {
            ZStack {
                Rectangle().foregroundColor(.black)
                content
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(entry.status.rawValue)")
                .font(.title2).fontWeight(.light).fontDesign(.monospaced)
                .foregroundStyle(entry.status.color)
            HStack(spacing: 8) {
                Text(timerInterval: entry.timerInterval, pauseTime: entry.isPaused ? entry.timerInterval.lowerBound : nil)
                    .foregroundStyle(.white)
                    .font(.title).fontWeight(.regular)
                    .monospacedDigit()
                Text(entry.status.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(entry.status.color)
            }
        }
    }
}

struct iOSWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })
    static let timerInterval = Date()...Date().addingTimeInterval(60)

    static var previews: some View {
        Group {
            iOSWidgetView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            iOSWidgetView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            iOSWidgetView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
