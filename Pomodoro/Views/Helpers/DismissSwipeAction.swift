//
//  DismissSwipeAction.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/26/23.
//

import SwiftUI
import Combine

class DismissSwipeAction: ObservableObject  {
    let signal = PassthroughSubject<Void, Never>()

    func callAsFunction() {
        signal.send()
    }
}
