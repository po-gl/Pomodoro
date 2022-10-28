//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Porter Glines on 10/27/22.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),
                    status: .work,
                    timeRemaining: PomoTimer.defaultWorkTime,
                    configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let pomoTimer = PomoTimer()
        pomoTimer.restoreFromUserDefaults()
        
        let now = Date()
        let entry = SimpleEntry(date: now,
                                status: pomoTimer.getStatus(atDate: now),
                                timeRemaining: pomoTimer.timeRemaining(atDate: now),
                                configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let pomoTimer = PomoTimer()
        pomoTimer.restoreFromUserDefaults()

        
        let work = PomoTimer.defaultWorkTime
        let rest = PomoTimer.defaultRestTime
        let breakTime = PomoTimer.defaultBreakTime
        
        let totalSeconds = (work + 1.0) * Double(pomoTimer.pomoCount) + (rest + 1.0) * Double(pomoTimer.pomoCount) + (breakTime + 1.0)
        let totalMinutes = totalSeconds / 60.0
        
        let currentDate = Date()
        for timeOffset in 0 ..< Int(totalMinutes)+1 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: timeOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate,
                                    status: pomoTimer.getStatus(atDate: entryDate),
                                    timeRemaining: pomoTimer.timeRemaining(atDate: entryDate),
                                    configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        return [
            IntentRecommendation(intent: ConfigurationIntent(), description: "Emoji Progress")
        ]
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    var status: PomoStatus
    var timeRemaining: TimeInterval
    let configuration: ConfigurationIntent
}


struct WatchWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ProgressView(value: entry.timeRemaining, total: getTotalForStatus(entry.status)) {
            Text("\(getIconForStatus(entry.status))")
                .font(.system(size: 20))
        }
            .progressViewStyle(.circular)
    }
    
    
    func getIconForStatus(_ status: PomoStatus) -> String {
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
    
    func getTotalForStatus(_ status: PomoStatus) -> Double {
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
}

@main
struct WatchWidget: Widget {
    let kind: String = "WatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pomodoro Status")
        .description("Track your pomodoro timer.")
    }
}

struct WatchWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })
    
    static var previews: some View {
        WatchWidgetEntryView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
