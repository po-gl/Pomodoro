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
    
    let shouldAddMinuteByMinuteEntries: Bool
    
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
        
        let now = Date()
        addEntry(for: now, &entries, configuration, pomoTimer)

        addTransitionEntries(&entries, configuration, pomoTimer)
        
        if shouldAddMinuteByMinuteEntries {
            addByMinuteEntries(&entries, configuration, pomoTimer)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    
    private let work = PomoTimer.defaultWorkTime
    private let rest = PomoTimer.defaultRestTime
    private let breakTime = PomoTimer.defaultBreakTime
    
    
    private func addTransitionEntries(_ entries: inout [SimpleEntry], _ configuration: ConfigurationIntent, _ pomoTimer: PomoTimer) {
        let currentDate = Date()
        var runningTime = 0.0
        for i in 0..<(pomoTimer.pomoCount-1) * 2 {
            let workOrRest = i % 2 == 0 ? work : rest
            runningTime += workOrRest + 1.0
            
            let entryDate = currentDate.addingTimeInterval(runningTime)
            addEntry(for: entryDate, &entries, configuration, pomoTimer)
        }
        
        runningTime += breakTime + 1.0
        let entryDate = currentDate.addingTimeInterval(runningTime)
        addEntry(for: entryDate, &entries, configuration, pomoTimer)
    }
    
    
    private func addByMinuteEntries(_ entries: inout [SimpleEntry], _ configuration: ConfigurationIntent, _ pomoTimer: PomoTimer) {
        let totalSeconds = (work + 1.0) * Double(pomoTimer.pomoCount) + (rest + 1.0) * Double(pomoTimer.pomoCount) + (breakTime + 1.0)
        let totalMinutes = totalSeconds / 60.0
        
        let currentDate = Date()
        for timeOffset in 0 ..< Int(totalMinutes)-1 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: timeOffset, to: currentDate)!
            addEntry(for: entryDate, &entries, configuration, pomoTimer)
        }
    }
    
    
    private func addEntry(for entryDate: Date, _ entries: inout [SimpleEntry], _ configuration: ConfigurationIntent, _ pomoTimer: PomoTimer) {
        let entry = SimpleEntry(date: entryDate,
                                status: pomoTimer.getStatus(atDate: entryDate),
                                timeRemaining: pomoTimer.timeRemaining(atDate: entryDate),
                                configuration: configuration)
        entries.append(entry)
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        let description = shouldAddMinuteByMinuteEntries ? "Status with Progress" : "Status"
        return [ IntentRecommendation(intent: ConfigurationIntent(), description: description) ]
    }
}


struct SimpleEntry: TimelineEntry {
    var date: Date
    var status: PomoStatus
    var timeRemaining: TimeInterval
    let configuration: ConfigurationIntent
}


@main
struct PomoWidgets: WidgetBundle {
    var body: some Widget {
        StatusWatchWidget()
        ProgressWatchWidget()
    }
}

struct ProgressWatchWidget: Widget {
    let kind: String = "ProgressWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(shouldAddMinuteByMinuteEntries: true)) { entry in
            ProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Track your pomodoro timer.")
    }
}

struct ProgressWidgetView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            ProgressView(value: entry.timeRemaining, total: getTotalForStatus(entry.status)) {
                Text("\(getIconForStatus(entry.status))")
                    .font(.system(size: 20))
            }
            .progressViewStyle(.circular)
            .widgetAccentable()
        }
    }
}


struct StatusWatchWidget: Widget {
    let kind: String = "StatusWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(shouldAddMinuteByMinuteEntries: false)) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Pomodoro Status")
        .description("See your pomodoro timer status.")
    }
}

struct StatusWidgetView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text("\(getIconForStatus(entry.status))")
                .font(.system(size: 20))
            .progressViewStyle(.circular)
            .widgetAccentable()
        }
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


struct WatchWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })
    
    static var previews: some View {
        ProgressWidgetView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
