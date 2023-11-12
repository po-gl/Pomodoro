//
//  View+verticalOffsetEffect.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/11/23.
//

import SwiftUI

extension View {
    func verticalOffsetEffect(for offset: CGFloat, _ animation: Animation, factor: CGFloat = 1.0) -> some View {
        ModifiedContent (content: self, modifier: VerticalOffsetEffectModifier(offset: offset, animation: animation, factor: factor))
    }
}

struct VerticalOffsetEffectModifier: ViewModifier {
    let offset: CGFloat
    let animation: Animation
    let factor: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: offset * factor)
            .animation(animation, value: offset)
    }
}
