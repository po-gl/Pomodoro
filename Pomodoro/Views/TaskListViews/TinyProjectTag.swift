//
//  TinyProjectTag.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/27/23.
//

import SwiftUI

struct TinyProjectTag: View {
    @Environment(\.colorScheme) private var colorScheme

    var color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(180))
            .brightness(colorScheme == .dark ? -0.09 : 0.0)
            .saturation(colorScheme == .dark ? 0.85 : 1.05)
    }
}

#Preview {
    Grid(horizontalSpacing: 2, verticalSpacing: 2) {
        GridRow {
            TinyProjectTag(color: .barRest)
            TinyProjectTag(color: .barWork)
        }
        GridRow {
            TinyProjectTag(color: .barLongBreak)
            TinyProjectTag(color: .end)
        }
        GridRow {
            TinyProjectTag(color: .accent)
        }
    }
}
