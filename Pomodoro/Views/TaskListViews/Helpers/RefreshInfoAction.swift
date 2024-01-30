//
//  RefreshInfoAction.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/28/24.
//

import Foundation
import Combine

class RefreshInfoAction: ObservableObject {
    let signal = PassthroughSubject<Void, Never>()

    func callAsFunction() {
        signal.send()
    }
}
