//
//  BuddyView.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct BuddyView: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var buddies: [Buddy] = [.tomato, .blueberry]
    
    var body: some View {
        ZStack {
            ForEach(Array(buddies.enumerated()), id: \.element) { index, buddy in
                AnimatedBuddy(buddy)
                    .offset(x: Double(index*18))
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
}

struct BuddyView_Previews: PreviewProvider {
    static let pomoTimer = PomoTimer()
    static var previews: some View {
        BuddyView(pomoTimer: pomoTimer)
            .frame(width: 20)
    }
}
