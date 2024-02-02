//
//  OnBoardingViewBackground.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/1/24.
//

import SwiftUI

struct OnBoardViewBackground: View {
    @Environment(\.colorScheme) var colorScheme
    var color: Color
    let t0 = Date.now

    var offset: CGFloat {
        colorScheme == .dark ? 0.0 : 60.0
    }

    var topColor: Color {
        colorScheme == .dark ? color : .black
    }
    var bottomColor: Color {
        colorScheme == .dark ? .black : backgroundColor(for: color)
    }

    var body: some View {
        VStack(spacing: 0) {
            topColor
                .frame(height: 110 - offset)
                .overlay {
                    Rectangle()
                        .fill(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
                        .blendMode(.softLight)
                }
                .brightness(colorScheme == .dark ? 0.1 : 0.0)
                .overlay(alignment: .bottom) {
                    PickDivider
                }
                .compositingGroup()
                .zIndex(1)
            bottomColor
                .overlay {
                    Rectangle()
                        .fill(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
                        .opacity(0.6)
                        .blendMode(.softLight)
                }
                .brightness(colorScheme == .dark ? 0.0 : 0.1)
                .zIndex(0)
        }
        .drawingGroup()
    }
    @ViewBuilder var PickDivider: some View {
        if #available(iOS 17, *) {
            Rectangle()
                .colorEffect(ShaderLibrary.pickGradient(.boundingRect,
                                                        .float(t0.timeIntervalSinceNow),
                                                        .color(.black),
                                                        .float(0.0)))
                .allowsHitTesting(false)
                .frame(height: 80)
                .rotationEffect(.degrees(colorScheme == .dark ? 0 : 180))
                .offset(y: colorScheme == .dark ? 0 : 70)
                .animation(nil, value: colorScheme)
        } else {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, .black], startPoint: .bottom, endPoint: .top))
                    .frame(height: 30)
                    .offset(y: colorScheme == .dark ? 25 : -5)
                    .rotationEffect(.degrees(colorScheme == .dark ? 180 : 0))
                Image("PickGradient")
                    .frame(width: 0, height: 0)
                    .offset(y: colorScheme == .dark ? 15 : 45)
                    .rotationEffect(.degrees(colorScheme == .dark ? 180 : 0))
            }
            .animation(nil, value: colorScheme)
            .compositingGroup()
            .frame(height: 0)
        }
    }
    
    private func backgroundColor(for color: Color) -> Color {
        switch color {
        case .barWork:
            return .backgroundWork
        case .barRest:
            return .backgroundRest
        case .barLongBreak:
            return .backgroundLongBreak
        default:
            return .backgroundStopped
        }
    }
}
