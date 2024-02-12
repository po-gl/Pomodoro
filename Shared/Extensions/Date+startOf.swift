//
//  Date+startOf.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/7/24.
//

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfWeek: Date {
        Calendar.current.startOfWeek(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay)!
    }

    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: self.startOfWeek)!
    }
}
