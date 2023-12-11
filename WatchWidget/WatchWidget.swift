//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Porter Glines on 10/27/22.
//

import WidgetKit
import SwiftUI
import Intents

struct ProgressWatchWidget: Widget {
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
        if #available(iOSApplicationExtension 17, watchOS 10, *) {
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
            progressGradient().mask(
                CircularProgressView()
            )
            .overlay {
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
    func CircularProgressView() -> some View {
        if !entry.isPaused {
            ProgressView(timerInterval: entry.timerInterval, countsDown: true, label: {}, currentValueLabel: {})
                .progressViewStyle(.circular)
        } else {
            let progressPercent = (entry.timerInterval.upperBound.timeIntervalSince1970 - entry.date.timeIntervalSince1970) / entry.status.defaultTime
            ProgressView(value: progressPercent)
                .progressViewStyle(.circular)
        }
    }

    func progressGradient() -> AngularGradient {
        AngularGradient(stops: [
            .init(color: Color(hex: 0xE05499), location: 0.0),
            .init(color: Color(hex: 0xFF6347), location: 0.2),
            .init(color: Color(hex: 0xD2544F), location: 0.4),

            .init(color: Color(hex: 0x30E277), location: 0.7),
            .init(color: Color(hex: 0x76E298), location: 0.9),

            .init(color: Color(hex: 0xE05499), location: 1.0)

        ], center: .center, startAngle: .degrees(0-60), endAngle: .degrees(360-60))
    }
}

struct CornerProgressWidget: Widget {
    let kind: String = "ProgressWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: true)) { entry in
            CornerProgressWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.accessoryCorner])
    }
}

struct CornerProgressWidgetView: View {
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        if #available(iOSApplicationExtension 17, watchOS 10, *) {
            MainCornerProgressWidgetView()
                .containerBackground(for: .widget) {
                    Color.white
                }
                .widgetCurvesContent()
        } else {
            MainCornerProgressWidgetView()
        }
    }

    @ViewBuilder
    func MainCornerProgressWidgetView() -> some View {
        ZStack {
            ZStack {
                if entry.isPaused {
                    Leaf(size: 24)
                } else {
                    Text(entry.status.icon)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                }
            }
            .widgetLabel {
                CornerProgressView()
            }
            .widgetAccentable()
        }
    }

    @ViewBuilder
    func CornerProgressView() -> some View {
        if !entry.isPaused {
            ProgressView(timerInterval: entry.timerInterval, countsDown: true, label: {}, currentValueLabel: {})
                .tint(progressGradient())
        } else {
            let progressPercent = (entry.timerInterval.upperBound.timeIntervalSince1970 - entry.date.timeIntervalSince1970) / entry.status.defaultTime
            ProgressView(value: progressPercent)
                .tint(progressGradient())
        }
    }

    func progressGradient() -> AngularGradient {
        AngularGradient(stops: [
            .init(color: Color(hex: 0xE05499), location: 0.0),

            .init(color: Color(hex: 0xE05499), location: 0.1),
            .init(color: Color(hex: 0xFF6347), location: 0.2),
            .init(color: Color(hex: 0xD2544F), location: 0.4),

            .init(color: Color(hex: 0x30E277), location: 0.7),
            .init(color: Color(hex: 0x76E298), location: 1.0)
        ], center: .center, startAngle: .degrees(0-60), endAngle: .degrees(360-60))
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
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
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
func Leaf(size: Double = 18) -> some View {
    Text(Image(systemName: "leaf.fill"))
        .font(.system(size: size))
        .foregroundColor(Color(hex: 0x31E377))
        .saturation(0.6)
}

struct WatchWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })
    static let timerInterval = Date()...Date().addingTimeInterval(60)

    static var previews: some View {
        Group {
            CornerProgressWidgetView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            ProgressWidgetView(entry: PomoTimelineEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        }
    }
}
