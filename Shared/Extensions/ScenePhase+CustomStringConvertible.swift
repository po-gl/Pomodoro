//
//  ScenePhase+CustomStringConvertible.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/16/23.
//

import SwiftUI

extension ScenePhase: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            "active"
        case .inactive:
            "inactive"
        case .background:
            "background"
        @unknown default:
            "unknown"
        }
    }
}
