//
//  Scene+backDeployedDefaultSize.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/2/24.
//

import SwiftUI

extension Scene {
    func backDeployedDefaultSize(width: CGFloat, height: CGFloat) -> some Scene {
        if #available(iOS 17, *) {
            return self.defaultSize(width: width, height: height)
        } else {
            return self
        }
    }
}
