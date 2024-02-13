//
//  StatusWidget.swift
//  iOSWidgetExtension
//
//  Created by Porter Glines on 12/10/23.
//

import SwiftUI
import WidgetKit

struct StatusWidget: Widget {
    let kind: String = "StatusWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: false)) { entry in
            StatusWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro Status")
        .description("See your pomodoro timer status.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct StatusWidgetView: View {
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.isPaused {
                LeafView()
            } else {
                Text(entry.status.icon)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
        .widgetAccentable()
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

struct StatusWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })

    static var previews: some View {
        let timerInterval = Date.now...Date.now.addingTimeInterval(60)
        let entry = PomoTimelineEntry(date: Date.now,
                                      status: .rest,
                                      task: nil,
                                      timerInterval: timerInterval,
                                      isPaused: false,
                                      currentSegment: 3,
                                      segmentCount: 6,
                                      workDuration: pomoTimer.workDuration,
                                      restDuration: pomoTimer.restDuration,
                                      breakDuration: pomoTimer.breakDuration,
                                      configuration: ConfigurationIntent())
        Group {
            StatusWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        }
    }
}
