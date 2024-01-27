//
//  EnvironmentValues+isReordering.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/25/24.
//

import SwiftUI

struct IsReorderingKey: EnvironmentKey {
    static let defaultValue = ObservableValue(false)
}

extension EnvironmentValues {
    var isReordering: ObservableValue<Bool> {
        get { self[IsReorderingKey.self] }
        set { self[IsReorderingKey.self] = newValue }
    }
}
