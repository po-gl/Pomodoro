//
//  Color+Interpolate.swift
//  Pomodoro
//
//  Created by Porter Glines on 5/31/23.
//

import SwiftUI


extension Color {
    
    var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r: r, g: g, b: b, a: a)
    }
    
    static func interpolate(from: Color, to: Color, progress: Double) -> Color {
        let fromComponents = from.components
        let toComponents = to.components
        
        let r = (1 - progress) * fromComponents.r + progress * toComponents.r
        let g = (1 - progress) * fromComponents.g + progress * toComponents.g
        let b = (1 - progress) * fromComponents.b + progress * toComponents.b
        let a = (1 - progress) * fromComponents.a + progress * toComponents.a
        
        return Color(uiColor: UIColor(red: r, green: g, blue: b, alpha: a))
    }
}
