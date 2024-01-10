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
    var status: PomoStatus
    var task: String?
    var timerInterval: ClosedRange<Date>
    var isPaused: Bool
    var currentSegment: Int
    var segmentCount: Int
    var workDuration: TimeInterval
    var restDuration: TimeInterval
    var breakDuration: TimeInterval
    let configuration: ConfigurationIntent

    static func new(for entryDate: Date, _ pomoTimer: PomoTimer, _ tasksOnBar: TasksOnBar, _ configuration: ConfigurationIntent) -> PomoTimelineEntry {
        let isPaused = pomoTimer.isPaused
        let status = pomoTimer.getStatus(atDate: entryDate)
        let index = pomoTimer.getIndex(atDate: entryDate)

        let task = index < tasksOnBar.tasksOnBar.count ? tasksOnBar.tasksOnBar[index] : nil

        let timeRemaining = pomoTimer.timeRemaining(atDate: entryDate)
        let timeStart = entryDate.addingTimeInterval(timeRemaining - pomoTimer.getDuration(for: status))
        let timeEnd = entryDate.addingTimeInterval(timeRemaining)

        return PomoTimelineEntry(date: entryDate,
                                 status: status,
                                 task: task,
                                 timerInterval: timeStart...timeEnd,
                                 isPaused: isPaused,
                                 currentSegment: status == .end ? pomoTimer.order.count : index,
                                 segmentCount: pomoTimer.order.count + 1, // +1 for .end segment
                                 workDuration: pomoTimer.workDuration,
                                 restDuration: pomoTimer.restDuration,
                                 breakDuration: pomoTimer.breakDuration,
                                 configuration: configuration)
    }
}
