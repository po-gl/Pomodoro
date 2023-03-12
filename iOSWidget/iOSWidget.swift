//
//  iOSWidget.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

import WidgetKit
import SwiftUI
import Intents


struct iOSProgressWatchWidget: Widget {
    let kind: String = "ProgressWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(shouldAddMinuteByMinuteEntries: true)) { entry in
            iOSProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct iOSProgressWidgetView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            ProgressView(value: entry.timeRemaining, total: getTotalForStatus(entry.status)) {
                Text(getIconForStatus(entry.status))
            }
            .progressViewStyle(.circular)
            .widgetAccentable()
        }
    }
}



struct iOSWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(shouldAddMinuteByMinuteEntries: true)) { entry in
            iOSWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pomodoro")
        .description("Track your pomodoro timer.")
    }
}

struct iOSWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.black)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.status.rawValue)")
                    .font(.title2).fontWeight(.light).fontDesign(.monospaced)
                    .foregroundColor(getColorForStatus(entry.status))
                HStack(spacing: 8) {
                    Text("\(entry.timeRemaining.compactTimerFormatted())")
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


fileprivate func getColorForStatus(_ status: PomoStatus) -> Color {
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

fileprivate func getIconForStatus(_ status: PomoStatus) -> String {
    switch status{
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


fileprivate func getTotalForStatus(_ status: PomoStatus) -> Double {
    switch status{
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
    
    static var previews: some View {
        Group {
            iOSProgressWidgetView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            iOSWidgetEntryView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            iOSWidgetEntryView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            iOSWidgetEntryView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
