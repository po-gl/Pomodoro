//
//  ChangerPage.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/28/22.
//

import SwiftUI

struct ChangerPage: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center) {
                Text("Pomos")
                    .foregroundColor(Color("BarWork"))
                    .font(.system(size: 26, weight: .light, design: .monospaced))
                Divider()
                Text("\(Array(repeating: "🍅", count: pomoTimer.pomoCount).joined(separator: ""))")
                    .font(.system(size: 22, weight: .regular))
            }
            Spacer()
            HStack {
                Spacer()
                Stepper {
                } onIncrement: {
                    basicHaptic()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pomoTimer.incrementPomos()
                    }
                } onDecrement: {
                    basicHaptic()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pomoTimer.decrementPomos()
                    }
                }
                Spacer()
            }
        }
    }
}
