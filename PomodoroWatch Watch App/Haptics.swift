//
//  Haptics.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import WatchKit

func workHaptic() {
    WKInterfaceDevice.current().play(.start)
}

func restHaptic() {
    WKInterfaceDevice.current().play(.stop)
}

func breakHaptic() {
    WKInterfaceDevice.current().play(.success)
}

func basicHaptic() {
    WKInterfaceDevice.current().play(.click)
}
