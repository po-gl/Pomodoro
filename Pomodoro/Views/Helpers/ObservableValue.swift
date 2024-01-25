//
//  ObservableValue.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/23.
//

import Combine

class ObservableValue<V: Equatable & Hashable>: ObservableObject {
    @Published var value: V

    init(_ value: V) {
        self.value = value
    }
}
