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
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: {
                    resetHaptic()
                    withAnimation(.easeIn(duration: 0.2)){
                        pomoTimer.reset()
                    }
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 60)
                            .foregroundColor(pomoTimer.isPaused ? .orange : Color("GrayedOut"))
                            .frame(width: 130, height: 60)
                        Text("Reset")
                            .font(.system(size: 20).monospaced())
                            .foregroundColor(.white)
                    }
                })
                .disabled(!pomoTimer.isPaused)
                Spacer()

                Button(action: {
                    basicHaptic()
                    withAnimation(.easeIn(duration: 0.2)){
                        pomoTimer.toggle()
                    }
                }, label: {
                    RoundedRectangle(cornerRadius: 60)
                        .foregroundColor(pomoTimer.isPaused ? Color("BarWork") : Color("BarLongBreak"))
                        .frame(width: 130, height: 60)
                        .reverseMask {
                            Text(pomoTimer.isPaused ? "Start" : "Stop")
                                .font(.system(size: 20).monospaced())
                        }
                })
                .disabled(pomoTimer.getStatus() == .end)
                .foregroundColor(pomoTimer.isPaused ? .blue : .accentColor)
                Spacer()
            }
        }
    }
}
