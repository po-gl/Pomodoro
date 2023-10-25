//
//  ObservableBool.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/23.
//

import Combine

class ObservableBool: ObservableObject {
    @Published var value: Bool

    init(_ value: Bool) {
        self.value = value
    }
}
