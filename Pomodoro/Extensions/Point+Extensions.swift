//
//  Point+Extensions.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/9/23.
//

import SwiftUI

extension CGPoint {
    func within(rect: CGRect) -> Bool {
        self.x >= rect.origin.x &&
        self.x <= rect.origin.x + rect.width &&
        self.y >= rect.origin.y &&
        self.y <= rect.origin.y + rect.height
    }

    func adjusted(for geometry: GeometryProxy) -> CGPoint {
        var translated = self
        translated.y += geometry.size.height/2
        return translated
    }
}
