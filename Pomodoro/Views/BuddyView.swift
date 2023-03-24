//
//  BuddyView.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct BuddyView: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var metrics: GeometryProxy
    var barWidth: Double { metrics.size.width - 32.0 }
    
#if os(iOS)
    let startingXOffset: Double = 15
    var endingXOffset: Double { barWidth - 70 }
#elseif os(watchOS)
    let startingXOffset: Double = 5
    var endingXOffset: Double { barWidth - 55 }
#endif
    
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
        .offset(x: -metrics.size.width/2 + startingXOffset)
        .offset(x: xOffsetForProgress())
    }
    
    @ViewBuilder
    private func AnimatedBuddy(_ buddy: Buddy) -> some View {
        if pomoTimer.isPaused {
            SitAnimation(buddy: buddy)
        } else {
            WalkAnimation(buddy: buddy)
        }
    }
    
    private func xOffsetForProgress() -> Double {
        let safeBarWidth = max(endingXOffset, 40)
        return (barWidth * pomoTimer.getProgress()).clamped(to: 40...safeBarWidth)
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
        GeometryReader { proxy in
            BuddyView(pomoTimer: pomoTimer, metrics: proxy)
                .frame(width: 20)
        }
    }
}
