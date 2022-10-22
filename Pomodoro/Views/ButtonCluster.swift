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
        HStack {
            Spacer()
            Button(action: {
                pomoTimer.reset()
            }, label: {
                Text("Reset")
                    .font(.system(size: 20).monospaced())
                    .foregroundColor(pomoTimer.isPaused ? .orange : .gray)
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
