//
//  PomoTime.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation


class PomoTime {
    enum PomoStatus {
        case work
        case rest
        case longBreak
    }
    private var timeInterval: TimeInterval
    private var status: PomoStatus
    
    init(_ time: TimeInterval, _ status: PomoStatus) {
        self.timeInterval = time
        self.status = status
    }
    
    func getTime() -> TimeInterval {
        return timeInterval
    }
    
    func getStatus() -> PomoStatus {
        return status
    }
    
    func getStatusString() -> String {
        switch status {
        case .work:
            return "Work"
        case .rest:
            return "Rest"
        case .longBreak:
            return "Long Break"
        }
    }
}
