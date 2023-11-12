//
//  AngledText.swift
//  Pomodoro
//
//  Created by Porter Glines on 4/6/23.
//

import SwiftUI

struct AngledText: View {
    var text: String
    var height: Double = 150
    var lineWidth: Double = 20
    var offset: Double = -40
    var angle: Double = -45

    var isBeingDragged: Bool = false

    var peekOffset = CGFloat.zero

    var textWidth: CGFloat {
        (height + peekOffset) / sin(abs(angle) * .pi / 180)
    }

    var body: some View {
        angledText
            .overlay(
                angledLines
                    .opacity(isBeingDragged ? 0.5 : 1.0)
            )
    }

    @ViewBuilder private var angledText: some View {
        let calculatedWidth = textWidth
        Text(text)
            .font(.system(.callout, design: .monospaced, weight: .medium))
            .frame(width: calculatedWidth, alignment: .leading)
            .offset(x: calculatedWidth/2)
            .rotationEffect(.degrees(angle))
            .offset(y: offset)
            .opacity(text.isEmpty ? 0.0 : 1.0)
    }

    @ViewBuilder private var angledLines: some View {
        Group {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .primary], startPoint: .leading, endPoint: .trailing))
                .frame(width: lineWidth, height: 1)
                .rotationEffect(.degrees(-90))
                .offset(x: -7, y: -23)
            Rectangle()
                .frame(width: lineWidth/2, height: 1)
                .offset(x: -5)
                .rotationEffect(.degrees(angle))
                .offset(y: offset)
        }
        .opacity(text.isEmpty ? 0.0 : 1.0)
    }
}
