//
//  TimeInterval+formatter.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation

extension TimeInterval {
    static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    static let compactFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    func timerFormatted() -> String {
        return TimeInterval.formatter.string(from: self)!
    }

    func compactTimerFormatted() -> String {
        return TimeInterval.compactFormatter.string(from: self)!
    }
}
