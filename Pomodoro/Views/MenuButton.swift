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
    @ObservedObject var pomoTimer: PomoTimer
    
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
            TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .frame(maxWidth: 40)
                            .foregroundColor(.white)
                            .opacity(0.0)
                        Text(getIconForStatus(status: pomoTimer.getStatus(atDate: context.date)))
                            .font(.system(size: 20))
                            .shadow(radius: 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingManageTimer) {
            Text("Managing saved timers")
        }
        .disabled(true)
    }
    
    
    private func getIconForStatus(status: PomoStatus) -> String {
        switch status {
        case .work:
            return "🌶️"
        case .rest:
            return "🍉🍇🍌"
        case .longBreak:
            return "🏖️"
        case .end:
            return "🎉"
        }
    }
}
