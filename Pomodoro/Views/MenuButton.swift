//
//  MenuButton.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/21/22.
//

import Foundation
import SwiftUI

struct MenuButton: View {
    var body: some View {
        Menu {
            Button(action: {}) {
                Label("Manage Timers", systemImage: "clock.arrow.2.circlepath")
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
                    Image(systemName: "cloud.rain.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 20))
                        .shadow(radius: 20)
                }
            }
        }
    }
}
