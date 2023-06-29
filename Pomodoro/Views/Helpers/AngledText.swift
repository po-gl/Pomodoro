//
//  AngledText.swift
//  Pomodoro
//
//  Created by Porter Glines on 4/6/23.
//

import SwiftUI

struct AngledText: View {
    var text: String
    var width: Double = 200
    var lineWidth: Double = 20
    var offset: Double = -40
    
    var isBeingDragged: Bool = false
    
    var body: some View {
        AngledText()
            .overlay(
                AngledLines()
                    .opacity(isBeingDragged ? 0.5 : 1.0)
            )
    }
    
    @ViewBuilder
    private func AngledText() -> some View {
        Text(text)
            .font(.system(.callout, design: .monospaced, weight: .medium))
            .frame(width: width, alignment: .leading)
            .offset(x: width/2)
            .rotationEffect(.degrees(-45))
            .offset(y: offset)
            .opacity(text.isEmpty ? 0.0 : 1.0)
    }
    
    @ViewBuilder
    private func AngledLines() -> some View {
        Group {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .primary], startPoint: .leading, endPoint: .trailing))
                .frame(width: lineWidth, height: 1)
                .rotationEffect(.degrees(-90))
                .offset(x: -7,y: -23)
            Rectangle()
                .frame(width: lineWidth/2, height: 1)
                .offset(x: -5)
                .rotationEffect(.degrees(-45))
                .offset(y: offset)
        }
        .opacity(text.isEmpty ? 0.0 : 1.0)
    }
}
