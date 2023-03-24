//
//  Publishers+Keyboard.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/24/23.
//

import SwiftUI
import Combine

extension Publishers {
    static var keyboardOpened: AnyPublisher<Bool, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardDidShowNotification)
            .map { _ in true }
        
        return willShow
            .eraseToAnyPublisher()
    }
}
