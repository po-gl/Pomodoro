//
//  EndTimerHandler.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/12/23.
//

import SwiftUI

class EndTimerHandler {
    static let shared = EndTimerHandler()
    
    var haptics = Haptics()
    
    @AppStorage("hasEndFired", store: UserDefaults(suiteName: "group.com.po-gl-a.pomodoro")) var hasEndFired = false
    
    
    public func handle(status: PomoStatus) {
        switch status {
        case .work:
            haptics.workHaptic()
        case .rest:
            haptics.restHaptic()
        case .longBreak:
            haptics.breakHaptic()
        case .end:
            guard !hasEndFired else { return }
            haptics.breakHaptic()
            hasEndFired = true
        }
    }
}
