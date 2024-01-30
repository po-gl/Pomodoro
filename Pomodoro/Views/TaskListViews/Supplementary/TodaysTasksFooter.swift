//
//  TodaysTasksFooter.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/10/24.
//

import SwiftUI

struct TodaysTasksFooter: View {
    @Environment(\.colorScheme) var colorScheme
    let height: CGFloat = 24

    var brightness: Double { colorScheme == .dark ? 0.15 : 0.2 }
    var saturation: Double { colorScheme == .dark ? 1.05 : 0.8 }
    var opacity: Double { colorScheme == .dark ? 0.7 : 0.5 }

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(stops: [
                        .init(color: .barLongBreak, location: 0.0),
                        .init(color: .barRest.opacity(opacity), location: 0.3),
                        .init(color: .clear, location: 1.0)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .frame(height: height)
                .brightness(brightness)
                .saturation(saturation)
                .opacity(opacity)
            Rectangle()
                .fill(.primary)
                .frame(height: 1)
                .opacity(0.5)
        }
    }
}
