//
//  PomoStatus+properties.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/9/23.
//

import SwiftUI

extension PomoStatus {

    var color: Color {
        switch self {
        case .work:
            return Color("BarWork")
        case .rest:
            return Color("BarRest")
        case .longBreak:
            return Color("BarLongBreak")
        case .end:
            return Color("End")
        }
    }

    var icon: String {
        switch self {
        case .work:
            return "W"
        case .rest:
            return "R"
        case .longBreak:
            return "🏖️"
        case .end:
            return "🎉"
        }
    }
}
