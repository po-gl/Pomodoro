//
//  EnvironmentValues+dismissSwipe.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/26/23.
//

import SwiftUI

struct DismissSwipeKey: EnvironmentKey {
    static let defaultValue = DismissSwipeAction()
}

extension EnvironmentValues {
    var dismissSwipe: DismissSwipeAction {
        get { self[DismissSwipeKey.self] }
    }
}
