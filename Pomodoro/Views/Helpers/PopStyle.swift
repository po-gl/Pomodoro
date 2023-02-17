//
//  PopStyle.swift
//  Dialogue
//
//  Created by Porter Glines on 2/7/23.
//

import Foundation
import SwiftUI

struct PopStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    var color: Color
    
    var radius = 30.0
    
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .foregroundStyle(LinearGradient(stops: [.init(color: color, location: 0.0), .init(color: color, location: 0.5), .init(color: .white, location: 1.4)], startPoint: .leading, endPoint: .trailing))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(colorScheme == .dark ? Color("Gray") : .black, lineWidth: 2))
            .overlay(
                configuration.label
                    .foregroundColor(color.isDarkColor ? .white : .black)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
            )
            .opacity(configuration.isPressed ? 0.4 : 1.0)
    }
}
