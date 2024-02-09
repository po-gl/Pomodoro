//
//  TimeInterval+minOrHr.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/9/24.
//

import Foundation

extension TimeInterval {
    func minOrHr(includeUnit: Bool = true) -> String {
        if abs(self) < 3600 {
            return String(format: "%.1f", self / 60) + (includeUnit ? " min" : "")
        } else {
            return String(format: "%.1f", self / 3600) + (includeUnit ? " hr" : "")
        }
    }
}
