//
//  PomoTimelineEntry.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/10/23.
//

import Foundation
import WidgetKit

struct PomoTimelineEntry: TimelineEntry {
    var date: Date
    var isPaused: Bool
    var status: PomoStatus
    var timerInterval: ClosedRange<Date>
    let configuration: ConfigurationIntent

    static func new(for entryDate: Date, _ pomoTimer: PomoTimer, _ configuration: ConfigurationIntent) -> PomoTimelineEntry {
        let isPaused = pomoTimer.isPaused
        let status = pomoTimer.getStatus(atDate: entryDate)

        let timeRemaining = pomoTimer.timeRemaining(atDate: entryDate)
        let timeStart = entryDate.addingTimeInterval(timeRemaining - getTotalForStatus(status))
        let timeEnd = entryDate.addingTimeInterval(timeRemaining)

        return PomoTimelineEntry(date: entryDate,
                         isPaused: isPaused,
                         status: status,
                         timerInterval: timeStart...timeEnd,
                         configuration: configuration)
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
