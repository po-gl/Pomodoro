//
//  ChangerPage.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/28/22.
//

import SwiftUI

struct ChangerPage: View {
    @ObservedObject var pomoTimer: PomoTimer
    var pomoChangeAnimation: Animation = .interpolatingSpring(stiffness: 190, damping: 13)

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center) {
                PomodorosText
                Divider().frame(width: 80)
                CurrentPomoCount
            }
            Spacer()
            PomoStepper
                .padding()
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder private var PomodorosText: some View {
        Text("Pomodoros")
            .foregroundStyle(LinearGradient(stops: [.init(color: Color("BarWork"), location: 0), .init(color: .primary, location: 1.5)], startPoint: .leading, endPoint: .trailing))
            .font(.system(size: 24, weight: .semibold, design: .monospaced))
    }

    @ViewBuilder private var CurrentPomoCount: some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.pomoCount, id: \.self) { _ in
                Text("🍅")
                    .font(.system(size: 22, weight: .regular))
            }
        }
    }

    @ViewBuilder private var PomoStepper: some View {
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
        .focusable(false)
    }
}
