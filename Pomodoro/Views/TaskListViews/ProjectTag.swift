//
//  ProjectTag.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/27/23.
//

import SwiftUI

struct ProjectTag: View {
    @Environment(\.colorScheme) private var colorScheme

    let name: String
    let color: Color

    var body: some View {
        Text(name)
            .foregroundStyle(color)
            .padding(.vertical, 2).padding(.horizontal, 8)
            .brightness(colorScheme == .dark ? 0.2 : -0.5)
            .saturation(colorScheme == .dark ? 1.1 : 1.2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .rotationEffect(.degrees(180))
                    .brightness(colorScheme == .dark ? -0.35 : 0.15)
                    .saturation(colorScheme == .dark ? 0.4 : 0.6)
                    .opacity(colorScheme == .dark ? 0.6 : 0.5)
            )
            .opacity(colorScheme == .dark ? 1.0 : 0.8)
    }
}

#Preview {
    VStack {
        ProjectTag(name: "Apps", color: Color("BarRest"))
        ProjectTag(name: "Work", color: Color("BarWork"))
        ProjectTag(name: "Dev Environment", color: Color("BarLongBreak"))
        ProjectTag(name: "Issues", color: Color("End"))
        ProjectTag(name: "Embedded Project", color: Color("AccentColor"))
    }
}
