//
//  EndTimerHandler.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/12/23.
//

import SwiftUI

class EndTimerHandler {
    static let shared = EndTimerHandler()

    @AppStorage("hasEndFired", store: UserDefaults.pomo) var hasEndFired = false

    public func handle(status: PomoStatus) {
        switch status {
        case .work:
            Haptics.shared.workHaptic()
        case .rest:
            Haptics.shared.restHaptic()
        case .longBreak:
            Haptics.shared.breakHaptic()
        case .end:
            guard !hasEndFired else { return }
            Haptics.shared.breakHaptic()
            hasEndFired = true
        }
    }
}
