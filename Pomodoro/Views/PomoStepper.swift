//
//  PomoStepper.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/12/23.
//

import SwiftUI

struct PomoStepper: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var pomoTimer: PomoTimer

    var pomoChangeAnimation: Animation = .interpolatingSpring(stiffness: 190, damping: 13)

    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Text("\(pomoTimer.pomoCount) ")
                    .font(.system(size: 23, weight: .semibold, design: .monospaced))
                Text("pomodoros")
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
            }
            pomoStepper()
                .scaleEffect(0.8)
                .frame(width: 80)
        }
        .opacity(pomoTimer.isPaused ? 1.0 : 0.0)
        .frame(maxHeight: pomoTimer.isPaused ? 20 : 0)
        .animation(.default, value: pomoTimer.isPaused)
    }

    @ViewBuilder
    private func pomoStepper() -> some View {
        Stepper {
        } onIncrement: {
            basicHaptic()
            withAnimation(pomoChangeAnimation) {
                pomoTimer.incrementPomos()
            }
        } onDecrement: {
            basicHaptic()
            withAnimation(pomoChangeAnimation) {
                pomoTimer.decrementPomos()
            }
        }
    }
}
