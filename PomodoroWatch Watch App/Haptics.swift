//
//  Haptics.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import WatchKit

func workHaptic() {
    WKInterfaceDevice.current().play(.notification)
}

func restHaptic() {
    WKInterfaceDevice.current().play(.notification)
}

func breakHaptic() {
    WKInterfaceDevice.current().play(.success)
}

func basicHaptic() {
    WKInterfaceDevice.current().play(.click)
}

func startHaptic() {
    WKInterfaceDevice.current().play(.start)
}

func stopHaptic() {
    WKInterfaceDevice.current().play(.stop)
}

func resetHaptic() {
    WKInterfaceDevice.current().play(.directionUp)
}
