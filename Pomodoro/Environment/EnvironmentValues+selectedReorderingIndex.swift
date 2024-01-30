//
//  EnvironmentValues+selectedReorderingIndex.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/25/24.
//

import SwiftUI

struct SelectedReorderingIndexKey: EnvironmentKey {
    static let defaultValue = ObservableValue(-1)
}

extension EnvironmentValues {
    var selectedReorderingIndex: ObservableValue<Int> {
        get { self[SelectedReorderingIndexKey.self] }
        set { self[SelectedReorderingIndexKey.self] = newValue }
    }
}
