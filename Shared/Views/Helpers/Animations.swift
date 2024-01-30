//
//  Animations.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/29/24.
//

import Foundation

struct Animations {
    static func run(for buddy: Buddy) -> AnimatedImageData {
        switch buddy {
        default:
            return AnimatedImageData(imageNames: (1...10).map { "\(buddy.rawValue)\($0)" },
                                     interval: 0.1,
                                     loops: true)
        }
    }
    
    static func sit(for buddy: Buddy) -> AnimatedImageData {
        switch buddy {
        default:
            return AnimatedImageData(imageNames: (19...21).map { "\(buddy.rawValue)\($0)" },
                                     interval: 0.6,
                                     loops: false)
        }
    }

    static let pickIndicator = AnimatedImageData(imageNames: (1...10).map { "PickIndicator\($0)" },
                                                 interval: 0.2,
                                                 loops: true)
}
