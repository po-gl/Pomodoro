//
//  BackgroundDivider.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/18/24.
//

import SwiftUI

struct BackgroundDivider: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var pomoTimer: PomoTimer

    var metalPickOffset = CGFloat.zero

    private let min = -20.0
    private let max = 120.0
    var normalizedMetalPickOffset: CGFloat {
        return (metalPickOffset - min) / (max - min)
    }

    // Note: There is a lot of animation code in this struct to animate
    // Metal shader parameters outside of the typical SwiftUI Animation API
    // since the parameters otherwise don't animate.

    @State var tAnimateTask: Task<(), Never>?

    @State var useTime = false
    @State var t0 = Calendar.current.startOfDay(for: Date.now)
    @State var tIntervalOffset: TimeInterval = 0.0
    @State var tStopDate: Date = Calendar.current.startOfDay(for: Date.now)
    @State var tStoppedInterval: TimeInterval = 0.0

    var tUnpaused: TimeInterval {
        t0.timeIntervalSinceNow + tIntervalOffset
    }
    var tPaused: TimeInterval {
        tStoppedInterval
    }

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if useTime {
                    TimelineView(.animation) { _ in
                        Rectangle()
                            .colorEffect(ShaderLibrary.pickGradient(.boundingRect,
                                                                    .float(tUnpaused),
                                                                    .color(.black),
                                                                    .float(0.0)))
                    }
                } else {
                    Rectangle()
                        .colorEffect(ShaderLibrary.pickGradient(.boundingRect,
                                                                .float(tPaused),
                                                                .color(.black),
                                                                .float(normalizedMetalPickOffset)))
                }
            }
            .allowsHitTesting(false)
            .frame(height: 60)
            .rotationEffect(.degrees(colorScheme == .dark ? 0 : 180))
            .offset(y: colorScheme == .dark ? -25 : 17)
        }
        .animation(nil, value: colorScheme)
        .compositingGroup()
        .frame(height: 0)
        .onChange(of: pomoTimer.isPaused) {
            if pomoTimer.isPaused {
                useTime = false
                tStopDate = Date.now
                tStoppedInterval = tUnpaused
                
                tAnimateTask?.cancel()
                tAnimateTask = Task { @MainActor in
                    let duration = 2.0
                    let ticks: Int = Int(duration / (1.0 / 60.0))
                    for i in 0..<ticks {
                        let time = 1.0 / 60.0 * (1.0 - Double(i) / Double(ticks))
                        tStoppedInterval -= time
                        tStopDate.addTimeInterval(time)
                        try? await Task.sleep(for: .seconds(1.0 / 60.0))
                        if Task.isCancelled {
                            break
                        }
                    }
                }
            } else {
                tAnimateTask?.cancel()
                useTime = true
                tIntervalOffset += Date.now.timeIntervalSince(tStopDate)
            }
        }
        .onAppear {
            t0 = Date.now
            tStopDate = Date.now
            tStoppedInterval = 0.0
            tIntervalOffset = 0.0
            useTime = !pomoTimer.isPaused
        }
    }
}
