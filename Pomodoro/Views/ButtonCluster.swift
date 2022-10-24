//
//  ButtonCluster.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/21/22.
//

import Foundation
import SwiftUI
    

struct ButtonCluster: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var metrics: GeometryProxy
    
    var body: some View {
        ZStack {
            if pomoTimer.isPaused {
                Stepper {
                } onIncrement: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pomoTimer.incrementPomos()
                    }
                } onDecrement: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pomoTimer.decrementPomos()
                    }
                }
                .offset(x: getPomoStepperOffsetX() ,y: -245)
            }
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeIn(duration: 0.2)){
                        pomoTimer.reset()
                    }
                }, label: {
                    Text("Reset")
                        .font(.system(size: 20).monospaced())
                        .foregroundColor(pomoTimer.isPaused ? .orange : .secondary)
                })
                .disabled(!pomoTimer.isPaused)
                Spacer()

                Button(action: {
                    withAnimation(.easeIn(duration: 0.2)){
                        pomoTimer.toggle()
                    }
                }, label: {
                    Text(pomoTimer.isPaused ? "Start" : "Stop")
                        .font(.system(size: 30).monospaced())
                })
                Spacer()
            }
        }
    }
    
    private func getPomoStepperOffsetX() -> Double {
        let intervals = pomoTimer.order.map { $0.getTime() }
        let total = intervals.reduce(0, +)
        return -(intervals[pomoTimer.order.count-1] / total * (metrics.size.width - 32.0)) + 30
    }
}
