//
//  Date+compare.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/1/23.
//

import Foundation

extension Date {

    func distance(from date: Date, only component: Calendar.Component, calendar: Calendar = .current) -> Int {
        let end = calendar.component(component, from: self)
        let begin = calendar.component(component, from: date)
        return end - begin
    }

    func isSameDay(as date: Date) -> Bool {
        let sameDay = distance(from: date, only: .day) == 0
        let sameMonth = distance(from: date, only: .month) == 0
        let sameYear = distance(from: date, only: .year) == 0
        return sameDay && sameMonth && sameYear
    }

    func isToday(calendar: Calendar = .current) -> Bool {
        return self.isSameDay(as: Date.now)
    }
    
    func progressBetween(_ start: Date, _ end: Date) -> Double {
        self.timeIntervalSince(start) / end.timeIntervalSince(start)
    }
}
