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
    
    let withProgress: Bool
    
    func placeholder(in context: Context) -> PomoEntry {
        let now = Date()
        return PomoEntry(date: now,
                         isPaused: true,
                         status: .work,
                         timerInterval: now...now.addingTimeInterval(PomoTimer.defaultWorkTime),
                         configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (PomoEntry) -> ()) {
        let pomoTimer = PomoTimer()
        pomoTimer.restoreFromUserDefaults()
        
        let now = Date()
        let entry = PomoEntry.new(for: now, pomoTimer, configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<PomoEntry>) -> ()) {
        var entries: [PomoEntry] = []
        let pomoTimer = PomoTimer()
        pomoTimer.restoreFromUserDefaults()
        
        let now = Date()
        entries.append(PomoEntry.new(for: now, pomoTimer, configuration))

        if !pomoTimer.isPaused {
            let transitionEntries = addTransitionEntries(pomoTimer, configuration)
            entries.append(contentsOf: transitionEntries)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func addTransitionEntries(_ pomoTimer: PomoTimer, _ configuration: ConfigurationIntent) -> [PomoEntry] {
        var entries: [PomoEntry] = []
        
        let now = Date()
        let offset = 1.0
        var runningDate = now

        let limit = pomoTimer.pomoCount * 2 + 1
        var i = 0
        
        repeat {
            runningDate = runningDate.addingTimeInterval(pomoTimer.timeRemaining(atDate: runningDate)+offset)
            i += 1
            entries.append(PomoEntry.new(for: runningDate, pomoTimer, configuration))
            
        } while pomoTimer.timeRemaining(atDate: runningDate) > 0  && i < limit
        
        return entries
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        let description = withProgress ? "Status with Progress" : "Status"
        return [ IntentRecommendation(intent: ConfigurationIntent(), description: description) ]
    }
}


struct PomoEntry: TimelineEntry {
    var date: Date
    var isPaused: Bool
    var status: PomoStatus
    var timerInterval: ClosedRange<Date>
    let configuration: ConfigurationIntent
    
    static func new(for entryDate: Date, _ pomoTimer: PomoTimer, _ configuration: ConfigurationIntent) -> PomoEntry {
        let isPaused = pomoTimer.isPaused
        let status = pomoTimer.getStatus(atDate: entryDate)
        
        let timeRemaining = pomoTimer.timeRemaining(atDate: entryDate)
        let timeStart = entryDate.addingTimeInterval(timeRemaining - getTotalForStatus(status))
        let timeEnd = entryDate.addingTimeInterval(timeRemaining)
        
        return PomoEntry(date: entryDate,
                         isPaused: isPaused,
                         status: status,
                         timerInterval: timeStart...timeEnd,
                         configuration: configuration)
    }
}


struct ProgressWatchWidget: Widget {
    let kind: String = "ProgressWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(withProgress: true)) { entry in
            ProgressWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ProgressWidgetView : View {
    var entry: Provider.Entry

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
                    Text(getIconForStatus(entry.status))
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
            let progressPercent = (entry.timerInterval.upperBound.timeIntervalSince1970 - entry.date.timeIntervalSince1970) / getTotalForStatus(entry.status)
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
            
            .init(color: Color(hex: 0xE05499), location: 1.0),
            
        ], center: .center, startAngle: .degrees(0-60), endAngle: .degrees(360-60))
    }
}


struct StatusWatchWidget: Widget {
    let kind: String = "StatusWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(withProgress: false)) { entry in
            StatusWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro Status")
        .description("See your pomodoro timer status.")
#if os(watchOS)
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
#elseif os(iOS)
        .supportedFamilies([.accessoryCircular])
#endif
    }
}

struct StatusWidgetView : View {
    var entry: Provider.Entry

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
                Text(getIconForStatus(entry.status))
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

fileprivate func getIconForStatus(_ status: PomoStatus) -> String {
    switch status{
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
    static let timerInterval = Date()...Date().addingTimeInterval(60)
    
    static var previews: some View {
        ProgressWidgetView(entry: PomoEntry(date: Date(), isPaused: false, status: .work, timerInterval: timerInterval, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
