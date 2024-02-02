//
//  BuddyView.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct BuddyView: View {
    @Environment(\.isOnBoarding) var isOnBoarding
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

    @AppStorage("enableBuddies", store: UserDefaults.pomo) var enableBuddies = true
    @State var buddies: [Buddy] = []

    var xOffsetForProgress: Double {
        let startXOffset = Double(buddies.count) * 13
        let safeBarWidth = max(endingXOffset, startingXOffset)
        guard startXOffset < safeBarWidth else { return 0.0 }
        return (barWidth * pomoTimer.getProgress()).clamped(to: startXOffset...safeBarWidth)
    }

    var startStopAnimation: Animation? {
        isOnBoarding ? nil : .interpolatingSpring(stiffness: 190, damping: 13)
    }

    var body: some View {
        HStack(spacing: -3) {
            ForEach(Array(buddies.enumerated()), id: \.element) { _, buddy in
                animatedBuddy(buddy)
                    .frame(width: buddy == .banana ? 40 : 20)
            }
        }
        .onAppear {
            buddies = BuddySelection.shared.selectedBuddies.shuffled()
        }
        .animation(startStopAnimation, value: pomoTimer.isPaused)
        .offset(x: -metrics.size.width/2 + startingXOffset)
        .offset(x: xOffsetForProgress)
        .animation(pomoTimer.isPaused ? .spring(duration: 1.8) : startStopAnimation, value: xOffsetForProgress)
        .opacity(enableBuddies ? 1.0 : 0.0)
        .animation(.default, value: enableBuddies)
        .onChange(of: BuddySelection.shared.selection) { _ in
            buddies = BuddySelection.shared.selectedBuddies
        }
    }

    @ViewBuilder
    private func animatedBuddy(_ buddy: Buddy) -> some View {
        let animationData = pomoTimer.isPaused ? Animations.sit(for: buddy) : Animations.run(for: buddy)
        AnimatedImage(data: animationData)
    }
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
