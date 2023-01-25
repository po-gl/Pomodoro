//
//  TimeInterval+formatter.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation

extension TimeInterval {
    static var formatter = DateComponentsFormatter()
    
    func timerFormatted() -> String {
        TimeInterval.formatter.allowedUnits = [.hour, .minute, .second]
        TimeInterval.formatter.zeroFormattingBehavior = .pad
        return TimeInterval.formatter.string(from: self)!
    }
    
    func compactTimerFormatted() -> String {
        TimeInterval.formatter.allowedUnits = [.minute, .second]
        TimeInterval.formatter.zeroFormattingBehavior = .dropLeading
        return TimeInterval.formatter.string(from: self)!
    }
}
