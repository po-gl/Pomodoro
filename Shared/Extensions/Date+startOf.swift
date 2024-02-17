//
//  Date+startOf.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/7/24.
//

import Foundation

extension Date {

    var startOfHour: Date {
        Calendar.current.startOfHour(for: self)
    }

    var endOfHour: Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: self.startOfHour)!
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay)!
    }

    var startOfWeek: Date {
        Calendar.current.startOfWeek(for: self)
    }

    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: self.startOfWeek)!
    }
}
