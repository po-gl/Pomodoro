//
//  SwipeStyle.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/25/23.
//

import SwiftUI

struct SwipeStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    let width: CGFloat
    
    var primaryBrightness: Double { colorScheme == .dark ? 0.4 : -0.33 }
    var primarySaturation: Double { colorScheme == .dark ? 1.8 : 1.2 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.5 : 0.4 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }
    var backgroundOpacity: Double { colorScheme == .dark ? 0.6 : 0.5 }

    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.tint)
            .brightness(backgroundBrightness)
            .saturation(backgroundSaturation)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [.white.opacity(0.3), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .blendMode(.destinationOut)
                
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.tint, lineWidth: 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [.white.opacity(0.3), .clear],
                                                 startPoint: .top, endPoint: .bottom))
                            .blendMode(.destinationOut)
                    }
            }
            .frame(width: width)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .opacity(backgroundOpacity)
            .overlay {
                configuration.label
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .brightness(primaryBrightness)
                    .saturation(primarySaturation)
            }
    }
}
