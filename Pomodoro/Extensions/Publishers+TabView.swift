//
//  Publishers+TabView.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/23/24.
//

import Foundation
import Combine

extension Publishers {
    static var selectFirstTab: AnyPublisher<Bool, Never> {
        let pub = NotificationCenter.default.publisher(for: .selectFirstTab)
            .map { _ in
                true
            }
        return pub.eraseToAnyPublisher()
    }
}
