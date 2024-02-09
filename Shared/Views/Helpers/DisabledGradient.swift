//
//  DisabledGradient.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/8/24.
//

import SwiftUI

func disabledGradient(startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> LinearGradient {
    return LinearGradient(stops: [.init(color: Color("GrayedOut"), location: 0.5),
                                  .init(color: Color(hex: 0xEDDAD5), location: 1.1)],
                          startPoint: startPoint, endPoint: endPoint)
}
