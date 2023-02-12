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
        multiHaptic(8, 0.2, 0.05, 0.8, 0.65)
    }
    
    public func restHaptic() {
        multiHaptic(8, 0.25, 0.05, 0.8, 0.5)
    }
    
    public func breakHaptic() {
        multiHaptic(8, 0.3, 0.05, 0.8, 0.5)
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
        
        let start = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0)
        let end = CHHapticParameterCurve.ControlPoint(relativeTime: 1, value: 1)
        let parameter = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [start, end], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: [parameter])
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

public func heavyHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.impactOccurred()
}

public func resetHaptic() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}
