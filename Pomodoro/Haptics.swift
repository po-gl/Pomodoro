//
//  Haptics.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import CoreHaptics
import UIKit


class Haptics {
    private var engine: CHHapticEngine?
    
    public func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the haptics engine: \(error.localizedDescription)")
        }
    }
    
    
    public func workHaptic() {
        multiHaptic(5, 0.2, 0.05, 0.8, 0.65)
    }
    
    public func restHaptic() {
        multiHaptic(5, 0.25, 0.05, 0.8, 0.5)
    }
    
    public func breakHaptic() {
        multiHaptic(7, 0.3, 0.05, 0.8, 0.5)
    }
    
    
    private func multiHaptic(_ count: Int,
                     _ duration: Double, _ seperationDuration: Double,
                     _ intensity: Float, _ sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events: [CHHapticEvent] = []
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        for i in 0..<count {
            events.append(CHHapticEvent(eventType: .hapticContinuous,
                                        parameters: [intensity, sharpness],
                                        relativeTime: Double(i) * (duration + seperationDuration),
                                        duration: duration))
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0.0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription)")
        }
    }
}


public func basicHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}
