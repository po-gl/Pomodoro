//
//  PomoStepper.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/12/23.
//

import SwiftUI

struct PomoStepper: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var pomoTimer: PomoTimer

    var pomoChangeAnimation: Animation = .interpolatingSpring(stiffness: 190, damping: 13)

    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Text("\(pomoTimer.pomoCount) ")
                    .font(.system(.title2, design: .monospaced, weight: .semibold))
                Text("pomodoros")
                    .font(.system(.title3, design: .monospaced, weight: .regular))
            }
            pomoStepper
                .scaleEffect(0.8)
                .frame(width: 80)
        }
        .opacity(pomoTimer.isPaused ? 1.0 : 0.0)
        .frame(maxHeight: pomoTimer.isPaused ? 20 : 0)
        .animation(.default, value: pomoTimer.isPaused)
    }

    @ViewBuilder private var pomoStepper: some View {
        Stepper {
        } onIncrement: {
            ThrottledHaptics.shared.basic()
            withAnimation(pomoChangeAnimation) {
                pomoTimer.incrementPomos()
            }
        } onDecrement: {
            ThrottledHaptics.shared.basic()
            withAnimation(pomoChangeAnimation) {
                pomoTimer.decrementPomos()
            }
        }
    }
}
