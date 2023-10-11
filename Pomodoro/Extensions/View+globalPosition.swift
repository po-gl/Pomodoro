//
//  View+globalPosition.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/27/23.
//

import SwiftUI

extension View {
    func globalPosition(_ point: CGPoint) -> some View {
        ModifiedContent(content: self, modifier: GlobalPositionModifier(point: point))
    }
}

struct GlobalPositionModifier: ViewModifier {
    var point: CGPoint

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .position(x: geometry.size.width / 2 + (point.x - geometry.frame(in: .global).midX),
                          y: geometry.size.height / 2 + (point.y - geometry.frame(in: .global).midY))
        }
    }
}
