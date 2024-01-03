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

    func timerFormatted() -> String {
        return TimeInterval.formatter.string(from: self)!
    }

    /// Formats time in "m:ss" or dynamically "h:mm:ss"
    func compactTimerFormatted() -> String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let hourPortion = hours > 0 ? "\(hours):" : ""
        let minutesPortion = minutes < 10 && hours > 0 ? "0\(minutes):" : "\(minutes):"
        let secondsPortion = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return hourPortion + minutesPortion + secondsPortion
    }
}
