//
//  EndTimerHandler.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/12/23.
//

import Foundation

class EndTimerHandler {
    static let shared = EndTimerHandler()
    
#if os(iOS)
    var haptics = Haptics()
    
    public func handle(status: PomoStatus) {
        switch status {
        case .work:
            haptics.workHaptic()
        case .rest:
            haptics.restHaptic()
        case .longBreak:
            haptics.breakHaptic()
        case .end:
            haptics.breakHaptic()
        }
    }
    
#elseif os(watchOS)
    public func handle(status: PomoStatus) {
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
#endif
}
