//
//  Publishers+Toasts.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/21/24.
//

import Foundation
import Combine

extension Publishers {
    static var toast: AnyPublisher<Toast, Never> {
        let pub = NotificationCenter.default.publisher(for: .toast)
            .map { notification in
                if let toast = notification.object as? Toast {
                    return toast
                } else {
                    return Toast(message: "error")
                }
            }
        return pub.eraseToAnyPublisher()
    }
}
