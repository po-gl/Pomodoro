//
//  iOSWidget.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    
    let shouldAddMinuteByMinuteEntries: Bool = true
    
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


struct iOSWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.black)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.status.rawValue)")
                    .font(.system(size: 20, weight: .light, design: .monospaced))
                    .foregroundColor(getColorForStatus(entry.status))
                HStack(spacing: 8) {
                    Text("\(entry.timeRemaining.compactTimerFormatted())")
                        .foregroundColor(.white)
                        .font(.system(size: 30, weight: .regular))
                        .monospacedDigit()
                    Text("\(getIconForStatus(entry.status))")
                        .font(.system(size: 20))
                }
            }
        }
        .ignoresSafeArea()
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
}

struct iOSWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            iOSWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pomodoro")
        .description("Track your pomodoro timer.")
    }
}

struct iOSWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })
    
    static var previews: some View {
        Group {
            iOSWidgetEntryView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            iOSWidgetEntryView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            iOSWidgetEntryView(entry: SimpleEntry(date: Date(), status: .work, timeRemaining: PomoTimer.defaultWorkTime, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
