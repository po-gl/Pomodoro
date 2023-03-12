//
//  WalkAnimation.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct WalkAnimation: View {
    var imageNames: [String]
    
    init(buddy: Buddy) {
        imageNames = (1...10).map{ "\(buddy.rawValue)\($0)" }
    }
    
    var body: some View {
        AnimatedImage(imageNames: imageNames, loops: true)
    }
}
