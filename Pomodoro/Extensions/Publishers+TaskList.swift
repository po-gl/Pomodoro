//
//  Publishers+TaskList.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/14/24.
//

import Foundation
import Combine

extension Publishers {
    static var focusOnAdder: AnyPublisher<Bool, Never> {
        let pub = NotificationCenter.default.publisher(for: .focusOnAdder)
            .map { _ in
                true
            }
        return pub.eraseToAnyPublisher()
    }
}
