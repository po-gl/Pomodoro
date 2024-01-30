//
//  EnvironmentValues+refreshInfo.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/28/24.
//

import SwiftUI

struct RefreshInfoKey: EnvironmentKey {
    static let defaultValue = RefreshInfoAction()
}

extension EnvironmentValues {
    var refreshInfo: RefreshInfoAction {
        get { self[RefreshInfoKey.self] }
    }
}
