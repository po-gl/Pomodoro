//
//  EnvironmentValues+swipeActionsDisable.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/24/24.
//

import SwiftUI

struct SwipeActionsDisableKey: EnvironmentKey {
    static let defaultValue = ObservableValue(false)
}

extension EnvironmentValues {
    var swipeActionsDisabled: ObservableValue<Bool> {
        get { self[SwipeActionsDisableKey.self] }
        set { self[SwipeActionsDisableKey.self] = newValue }
    }
}
