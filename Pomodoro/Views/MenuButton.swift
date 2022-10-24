//
//  MenuButton.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/21/22.
//

import Foundation
import SwiftUI

struct MenuButton: View {
    @State var showingManageTimer: Bool = false
    
    var body: some View {
        Menu {
            Section {
                Button(action: {showingManageTimer.toggle()}) {
                    Label("Manage Timer", systemImage: "clock.arrow.2.circlepath")
                }
            }
            Button(action: {}) {
                Label("About", systemImage: "sparkles")
                    .symbolRenderingMode(.multicolor)
            }
        }
        label: {
            Button(action: {}) {
                ZStack {
                    Circle()
                        .frame(maxWidth: 40)
                        .foregroundColor(.white)
                        .opacity(0.0)
                    Text("🍅")
                        .font(.system(size: 20))
                        .shadow(radius: 20)
                }
            }
        }
        .sheet(isPresented: $showingManageTimer) {
            Text("Managing saved timers")
        }
        .disabled(true)
    }
}
