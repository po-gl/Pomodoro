//
//  EnvironmentValues+isOnBoarding.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/1/24.
//

import SwiftUI

struct IsOnBoardingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isOnBoarding: Bool {
        get { self[IsOnBoardingKey.self] }
        set { self[IsOnBoardingKey.self] = newValue }
    }
}
