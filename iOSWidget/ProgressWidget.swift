//
//  ProgressWidget.swift
//  iOSWidgetExtension
//
//  Created by Porter Glines on 12/10/23.
//

import SwiftUI
import WidgetKit

struct ProgressWidget: Widget {
    let kind: String = "ProgressWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: true)) { entry in
            ProgressWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ProgressWidgetView: View {
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        if #available(iOSApplicationExtension 17, *) {
            content
                .containerBackground(for: .widget) {
                    Color.white
                }
        } else {
            content
        }
    }

    @ViewBuilder var content: some View {
        ZStack {
            circularProgressView {
                if entry.isPaused {
                    LeafView(size: 22)
                } else {
                    Text(entry.status.icon)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                }
            }
            .progressViewStyle(.circular)
            .widgetAccentable()
        }
    }

    @ViewBuilder
    func circularProgressView(@ViewBuilder label: () -> some View) -> some View {
        if !entry.isPaused {
            ProgressView(timerInterval: entry.timerInterval, countsDown: true, label: {}, currentValueLabel: label)
                .progressViewStyle(.circular)
        } else {
            let progressPercent = (entry.timerInterval.upperBound.timeIntervalSince1970 - entry.date.timeIntervalSince1970) / entry.status.defaultTime
            ProgressView(value: progressPercent, label: label)
                .progressViewStyle(.circular)
        }
    }
}

struct ProgressWidget_Previews: PreviewProvider {
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
            ProgressWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        }
    }
}
