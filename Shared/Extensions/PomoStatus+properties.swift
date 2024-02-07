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
    
    var defaultTime: Double {
        switch self {
        case .work:
            return PomoTimer.defaultWorkTime
        case .rest:
            return PomoTimer.defaultRestTime
        case .longBreak:
            return PomoTimer.defaultBreakTime
        case .end:
            return 0.0
        }
    }

    func gradient(startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> LinearGradient {
        switch self {
        case .work:
            return LinearGradient(stops: [.init(color: self.color, location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: startPoint, endPoint: endPoint)
        case .rest:
            return LinearGradient(stops: [.init(color: self.color, location: 0.2),
                                          .init(color: Color(hex: 0xE8BEB1), location: 1.0)],
                                  startPoint: startPoint, endPoint: endPoint)
        case .longBreak:
            return LinearGradient(stops: [.init(color: self.color, location: 0.5),
                                          .init(color: Color(hex: 0xF5E1E1), location: 1.3)],
                                  startPoint: startPoint, endPoint: endPoint)
        case .end:
            return LinearGradient(stops: [.init(color: self.color, location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: startPoint, endPoint: endPoint)
        }
    }
}
