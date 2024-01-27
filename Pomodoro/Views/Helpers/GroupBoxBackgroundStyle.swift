//
//  GroupBoxBackgroundStyle.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/27/24.
//

import SwiftUI

struct GroupBoxBackgroundStyle: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        if environment.colorScheme == .dark {
            return Color.black.lighten(by: 0.07)
        } else {
            return Color("Background").lighten(by: 0.2)
        }
    }
}
