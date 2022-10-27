//
//  ButtonCluster.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import SwiftUI
    

struct ButtonCluster: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .foregroundColor(pomoTimer.isPaused ? .orange : Color(hex: 0x333333))
                .font(.system(size: 40))
                .onTapGesture {
                    resetHaptic()
                    withAnimation(.easeIn(duration: 0.2)){
                        pomoTimer.pause()
                        pomoTimer.reset()
                    }
                }
                .disabled(!pomoTimer.isPaused)
            Spacer()
            
            Image(systemName: pomoTimer.isPaused ? "play.circle.fill" : "pause.circle.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 40))
                .onTapGesture {
                    pomoTimer.isPaused ? startHaptic() : stopHaptic()
                    withAnimation(.easeIn(duration: 0.2)){
                        pomoTimer.toggle()
                    }
                }
        }
    }
}
