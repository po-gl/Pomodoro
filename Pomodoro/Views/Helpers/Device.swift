//
//  Device.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/25/24.
//

import SwiftUI

struct Device {
    static func isSmall(geometry: GeometryProxy) -> Bool {
        geometry.size.height < 650.0
    }
}
