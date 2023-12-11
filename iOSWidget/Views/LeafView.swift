//
//  LeafView.swift
//  iOSWidgetExtension
//
//  Created by Porter Glines on 12/10/23.
//

import SwiftUI

struct LeafView: View {
    var size: CGFloat = 18

    var body: some View {
        Text(Image(systemName: "leaf.fill"))
            .font(.system(size: size))
            .foregroundStyle(Color(hex: 0x31E377))
            .saturation(0.6)
    }
}
