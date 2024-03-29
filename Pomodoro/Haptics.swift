//
//  Haptics.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import CoreHaptics
import UIKit
import Combine
import OSLog

class Haptics {
    static public let shared = Haptics()

    private var engine: CHHapticEngine?

    private var stopTask: Task<(), Never>?

    public func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        stopTask?.cancel()

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            Logger().error("There was an error creating the haptics engine: \(error.localizedDescription)")
        }
    }

    public func workHaptic() {
        prepareHaptics()
        buildUpHaptic(softness: 1.1)
    }

    public func restHaptic() {
        prepareHaptics()
        buildUpHaptic(softness: 0.9)
    }

    public func breakHaptic() {
        prepareHaptics()
        buildUpHaptic(softness: 0.9)
    }

    private func buildUpHaptic(softness: Float = 1.0) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let duration = 1.6 // 2.2
        let overallDuration = 5.0
        var events: [CHHapticEvent] = []

        events.append(CHHapticEvent(eventType: .hapticContinuous,
                                    parameters: [CHHapticEventParameter(parameterID: .hapticIntensity,
                                                                        value: 0.7 * softness),
                                                 CHHapticEventParameter(parameterID: .hapticSharpness,
                                                                        value: 0.7 * softness)],
                                    relativeTime: 0.0, duration: duration))
        for i in 0..<6 {
            events.append(CHHapticEvent(eventType: .hapticTransient,
                                        parameters: [CHHapticEventParameter(parameterID: .hapticIntensity,
                                                                            value: 0.8 * softness),
                                                     CHHapticEventParameter(parameterID: .hapticSharpness,
                                                                            value: 0.9 * softness)],
                                        relativeTime: Double(i) * (0.1 + 0.1) + duration, duration: 0.1))
        }

        let controlPoints = [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.0, value: 0.1),
            CHHapticParameterCurve.ControlPoint(relativeTime: duration*0.81, value: 0.4147),
            CHHapticParameterCurve.ControlPoint(relativeTime: duration*0.95, value: 0.77),
            CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 1),
            CHHapticParameterCurve.ControlPoint(relativeTime: overallDuration, value: 1)
        ]
        let parameter = CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                               controlPoints: controlPoints,
                                               relativeTime: 0)

        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: [parameter])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0.0)

            stopTask = Task {
                try? await Task.sleep(for: .seconds(overallDuration))
                guard !Task.isCancelled else { return }
                try? await engine?.stop()
            }
        } catch {
            Logger().error("Failed to play pattern: \(error.localizedDescription)")
        }
    }
}

class ThrottledHaptics {
    static let shared = ThrottledHaptics()

    @Published private var basicHapticPublisher: Bool = false
    private var hapticSubscriber: AnyCancellable?

    init() {
        hapticSubscriber = $basicHapticPublisher
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .sink { _ in
                basicHaptic()
            }
    }

    func basic() {
        basicHapticPublisher.toggle()
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
