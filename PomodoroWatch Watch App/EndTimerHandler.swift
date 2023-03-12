//
//  EndTimerHandler.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 3/11/23.
//

import Foundation

class EndTimerHandler {
    static let shared = EndTimerHandler()
    
    public func handle(status: PomoStatus) {
        BackgroundSession.shared.stop()
        
        switch status {
        case .work:
            workHaptic()
        case .rest:
            restHaptic()
        case .longBreak:
            breakHaptic()
        case .end:
            breakHaptic()
        }
    }
}
