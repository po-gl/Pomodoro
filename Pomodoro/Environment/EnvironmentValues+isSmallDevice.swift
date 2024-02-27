//
//  EnvironmentValues+isSmallDevice.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/27/24.
//

import SwiftUI

struct IsSmallDeviceKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isSmallDevice: Bool {
        get { self[IsSmallDeviceKey.self] }
        set { self[IsSmallDeviceKey.self] = newValue }
    }
}
