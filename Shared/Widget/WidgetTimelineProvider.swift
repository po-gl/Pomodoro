//
//  WidgetTimelineProvider.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/10/23.
//

import SwiftUI
import WidgetKit
import Intents

struct WidgetTimelineProvider: IntentTimelineProvider {

    let withProgress: Bool

    func placeholder(in context: Context) -> PomoTimelineEntry {
        let now = Date()
        return PomoTimelineEntry(date: now,
                         isPaused: true,
                         status: .work,
                         timerInterval: now...now.addingTimeInterval(PomoTimer.defaultWorkTime),
                         configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (PomoTimelineEntry) -> Void) {
        let pomoTimer = PomoTimer()
        pomoTimer.restoreFromUserDefaults()

        let now = Date()
        let entry = PomoTimelineEntry.new(for: now, pomoTimer, configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<PomoTimelineEntry>) -> Void) {
        var entries: [PomoTimelineEntry] = []
        let pomoTimer = PomoTimer()
        pomoTimer.restoreFromUserDefaults()

        let now = Date()
        entries.append(PomoTimelineEntry.new(for: now, pomoTimer, configuration))

        if !pomoTimer.isPaused {
            let transitionEntries = addTransitionEntries(pomoTimer, configuration)
            entries.append(contentsOf: transitionEntries)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func addTransitionEntries(_ pomoTimer: PomoTimer, _ configuration: ConfigurationIntent) -> [PomoTimelineEntry] {
        var entries: [PomoTimelineEntry] = []

        let now = Date()
        let offset = 1.0
        var runningDate = now

        let limit = pomoTimer.pomoCount * 2 + 1
        var i = 0

        repeat {
            runningDate = runningDate.addingTimeInterval(pomoTimer.timeRemaining(atDate: runningDate)+offset)
            i += 1
            entries.append(PomoTimelineEntry.new(for: runningDate, pomoTimer, configuration))

        } while pomoTimer.timeRemaining(atDate: runningDate) > 0  && i < limit

        return entries
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        let description = withProgress ? "Status with Progress" : "Status"
        return [ IntentRecommendation(intent: ConfigurationIntent(), description: description) ]
    }
}
