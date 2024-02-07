//
//  Calendar+startOfHour.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/5/24.
//

import Foundation

extension Calendar {
    func startOfHour(for date: Date) -> Date {
        let hour = Calendar.current.component(.hour, from: date)
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
    }
}
