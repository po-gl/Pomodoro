//
//  BuddySelector.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/4/24.
//

import SwiftUI

struct BuddySelector: View {
    @Environment(\.colorScheme) var colorScheme

    let buddy: Buddy
    var isSelected: Bool = false

    var size = CGSize(width: 80, height: 80)
    var radius: CGFloat = 8
    private var padding: CGFloat { isSelected ? 28 : 38 }

    var body: some View {
        VStack(spacing: 0) {
            Image("\(buddy.rawValue)1")
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fill)
                .scaleEffect(x: -1)
                .frame(width: size.width - padding, height: size.height - padding)
                .padding(padding/2)
                .offset(x: buddy == .banana ? size.width/4 : 0, y: padding/2 - 5)
                .brightness(colorScheme == .dark ? 0.0 : 0.1)
                .clipped()
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: radius, bottomLeading: 0,
                                                              bottomTrailing: 0, topTrailing: radius))
                    .fill(.black)
                    .brightness(colorScheme == .dark ? 0.0 : 0.15)
                )
                .overlay(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: radius, bottomLeading: 0,
                                                              bottomTrailing: 0, topTrailing: radius))
                    .fill(Color(buddy.rawValue))
                    .brightness(colorScheme == .dark ? -0.08 : 0.35)
                    .saturation(colorScheme == .dark ? 0.85 : 1.05)
                    .opacity(isSelected ? 0.7 : 0.0)
                    .reverseMask {
                        Circle()
                            .fill(.white)
                            .blur(radius: 8)
                    }
                )
                .animation(.default, value: isSelected)
            Text(buddy.rawValue.capitalized)
                .font(.callout)
                .frame(width: size.width)
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0, bottomLeading: radius,
                                                              bottomTrailing: radius, topTrailing: 0))
                    .fill(Color(hex: colorScheme == .dark ? 0x333333 : 0xEEEEEE).gradient)
                    .background(
                        UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0, bottomLeading: radius,
                                                                          bottomTrailing: radius, topTrailing: 0))
                        .fill(.black)
                        .brightness(colorScheme == .dark ? 0.0 : 0.15)
                    )
                )
        }
    }
}

#Preview {
    BuddySelector(buddy: .banana, isSelected: true)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 10).fill(.gray).opacity(0.5))
}
