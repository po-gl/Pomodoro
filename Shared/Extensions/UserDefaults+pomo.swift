//
//  UserDefaults+pomo.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/2/24.
//

import Foundation

extension UserDefaults {
    static var pomo: UserDefaults? {
        UserDefaults(suiteName: "group.com.po-gl-a.pomodoro")
    }
}
