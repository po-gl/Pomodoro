//
//  iOSWidget.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

import WidgetKit
import SwiftUI
import Intents

struct iOSProgressWidget: Widget {
    let kind: String = "ProgressWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: true)) { entry in
            iOSProgressWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct iOSProgressWidgetView: View {
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        if #available(iOSApplicationExtension 17, *) {
            MainProgressWidgetView()
                .containerBackground(for: .widget) {
                    Color.white
                }
        } else {
            MainProgressWidgetView()
        }
    }

    @ViewBuilder
    func MainProgressWidgetView() -> some View {
        ZStack {
            CircularProgressView {
                if entry.isPaused {
                    Leaf(size: 22)
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
    func CircularProgressView(@ViewBuilder label: () -> some View) -> some View {
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

struct iOSWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: true)) { entry in
            iOSWidgetEntryView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro")
        .description("Track your pomodoro timer.")
    }
}

struct iOSWidgetEntryView: View {
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.black)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.status.rawValue)")
                    .font(.title2).fontWeight(.light).fontDesign(.monospaced)
                    .foregroundColor(entry.status.color)
                HStack(spacing: 8) {
                    Text(timerInterval: entry.timerInterval, pauseTime: entry.isPaused ? entry.timerInterval.lowerBound : nil)
                        .foregroundColor(.white)
                        .font(.title).fontWeight(.regular)
                        .monospacedDigit()
                    Text(entry.status.icon)
                        .font(.system(size: 20))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct StatusWatchWidget: Widget {
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
        if #available(iOSApplicationExtension 17, watchOS 10, *) {
            MainStatusWidgetView()
                .containerBackground(for: .widget) {
                    Color.white
                }
        } else {
            MainStatusWidgetView()
        }
    }

    @ViewBuilder
    func MainStatusWidgetView() -> some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.isPaused {
                Leaf()
            } else {
                Text(entry.status.icon)
                    .font(.system(size: 20, weight: .medium, design: .serif))
            }
        }
        .widgetAccentable()
    }
}

@ViewBuilder
private func Leaf(size: Double = 18) -> some View {
    Text(Image(systemName: "leaf.fill"))
        .font(.system(size: size))
        .foregroundColor(Color(hex: 0x31E377))
        .saturation(0.6)
}

struct iOSWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })
    static let timerInterval = Date()...Date().addingTimeInterval(60)

    static var previews: some View {

        Group {
            iOSProgressWidgetView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .rest, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            iOSWidgetEntryView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            iOSWidgetEntryView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            iOSWidgetEntryView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
