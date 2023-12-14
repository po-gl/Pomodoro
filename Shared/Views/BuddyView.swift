//
//  BuddyView.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct BuddyView: View {
    @EnvironmentObject var pomoTimer: PomoTimer

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

    var xOffsetForProgress: Double {
        let safeBarWidth = max(endingXOffset, 40)
        return (barWidth * pomoTimer.getProgress()).clamped(to: 40...safeBarWidth)
    }

    var startStopAnimation: Animation = .interpolatingSpring(stiffness: 190, damping: 13)

    var body: some View {
        HStack(spacing: -3) {
            ForEach(Array(buddies.enumerated()), id: \.element) { _, buddy in
                animatedBuddy(buddy)
                    .frame(width: buddy == .banana ? 40 : 20)
            }
        }
        .onAppear {
            buddies.shuffle()
        }
        .animation(startStopAnimation, value: pomoTimer.isPaused)
        .offset(x: -metrics.size.width/2 + startingXOffset)
        .offset(x: xOffsetForProgress)
        .animation(pomoTimer.isPaused ? .spring(duration: 1.8) : startStopAnimation, value: xOffsetForProgress)
    }

    @ViewBuilder
    private func animatedBuddy(_ buddy: Buddy) -> some View {
        let paused = pomoTimer.isPaused
        let animationData = paused ? AnimatedImageData(imageNames: (19...21).map { "\(buddy.rawValue)\($0)" },
                                                       interval: 0.6)
                                   : AnimatedImageData(imageNames: (1...10).map { "\(buddy.rawValue)\($0)" },
                                                       loops: true)
        AnimatedImage(data: animationData)
    }
}

enum Buddy: String {
    case tomato
    case blueberry
    case banana
}

struct BuddyView_Previews: PreviewProvider {
    static let pomoTimer = PomoTimer()
    static var previews: some View {
        GeometryReader { proxy in
            BuddyView(metrics: proxy)
                .environmentObject(pomoTimer)
                .frame(width: 20)
        }
    }
}
