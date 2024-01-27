//
//  EnvironmentValues+selectedReorderingRect.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/25/24.
//

import SwiftUI

struct SelectedReorderingRectKey: EnvironmentKey {
    static let defaultValue = ObservableValue<CGRect>(.zero)
}

extension EnvironmentValues {
    var selectedReorderingRect: ObservableValue<CGRect> {
        get { self[SelectedReorderingRectKey.self] }
        set { self[SelectedReorderingRectKey.self] = newValue }
    }
}
