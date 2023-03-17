//
//  BuddyView.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct BuddyView: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var buddies: [Buddy] = [.tomato, .blueberry, .banana]
    
    var body: some View {
        HStack (spacing: -3) {
            ForEach(Array(buddies.enumerated()), id: \.element) { index, buddy in
                AnimatedBuddy(buddy)
                    .frame(width: buddy == .banana ? 40 : 20)
            }
        }
        .onAppear {
            buddies.shuffle()
        }
    }
    
    @ViewBuilder
    private func AnimatedBuddy(_ buddy: Buddy) -> some View {
        if pomoTimer.isPaused {
            SitAnimation(buddy: buddy)
        } else {
            WalkAnimation(buddy: buddy)
        }
    }
}

enum Buddy: String {
    case tomato = "tomato"
    case blueberry = "blueberry"
    case banana = "banana"
}

struct BuddyView_Previews: PreviewProvider {
    static let pomoTimer = PomoTimer()
    static var previews: some View {
        BuddyView(pomoTimer: pomoTimer)
            .frame(width: 20)
    }
}
