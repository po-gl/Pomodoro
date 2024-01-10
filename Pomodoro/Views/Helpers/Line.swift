//
//  Line.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/10/24.
//

import SwiftUI

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
