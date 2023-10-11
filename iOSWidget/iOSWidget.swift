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
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(withProgress: true)) { entry in
            iOSProgressWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct iOSProgressWidgetView: View {
    var entry: Provider.Entry

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
                    Text(getIconForStatus(entry.status))
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
            let progressPercent = (entry.timerInterval.upperBound.timeIntervalSince1970 - entry.date.timeIntervalSince1970) / getTotalForStatus(entry.status)
            ProgressView(value: progressPercent, label: label)
                .progressViewStyle(.circular)
        }
    }
}

struct iOSWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(withProgress: true)) { entry in
            iOSWidgetEntryView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro")
        .description("Track your pomodoro timer.")
    }
}

struct iOSWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.black)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.status.rawValue)")
                    .font(.title2).fontWeight(.light).fontDesign(.monospaced)
                    .foregroundColor(getColorForStatus(entry.status))
                HStack(spacing: 8) {
                    Text(timerInterval: entry.timerInterval, pauseTime: entry.isPaused ? entry.timerInterval.lowerBound : nil)
                        .foregroundColor(.white)
                        .font(.title).fontWeight(.regular)
                        .monospacedDigit()
                    Text("\(getIconForStatus(entry.status))")
                        .font(.system(size: 20))
                }
            }
        }
        .ignoresSafeArea()
    }
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

private func getIconForStatus(_ status: PomoStatus) -> String {
    switch status {
    case .work:
        return "W"
    case .rest:
        return "R"
    case .longBreak:
        return "🏖️"
    case .end:
        return "🎉"
    }
}

private func getTotalForStatus(_ status: PomoStatus) -> Double {
    switch status {
    case .work:
        return PomoTimer.defaultWorkTime
    case .rest:
        return PomoTimer.defaultRestTime
    case .longBreak:
        return PomoTimer.defaultBreakTime
    case .end:
        return 1.0
    }
}

struct iOSWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })
    static let timerInterval = Date()...Date().addingTimeInterval(60)

    static var previews: some View {

        Group {
            iOSProgressWidgetView(entry: PomoEntry(date: Date(), isPaused: false, status: .rest, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            iOSWidgetEntryView(entry: PomoEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            iOSWidgetEntryView(entry: PomoEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            iOSWidgetEntryView(entry: PomoEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
