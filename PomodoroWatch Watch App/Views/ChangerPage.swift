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
                Text("Pomodoros")
                    .foregroundColor(Color("BarWork"))
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                Divider()
                CurrentPomoCount()
            }
            Spacer()
            HStack {
                Spacer()
                PomoStepper()
                Spacer()
            }
        }
    }
    
    
    @ViewBuilder
    private func CurrentPomoCount() -> some View {
        Text("\(Array(repeating: "🍅", count: pomoTimer.pomoCount).joined(separator: ""))")
            .font(.system(size: 22, weight: .regular))
    }
    
    @ViewBuilder
    private func PomoStepper() -> some View {
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
