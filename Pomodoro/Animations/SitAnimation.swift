//
//  SitAnimation.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct SitAnimation: View {
    var imageNames: [String]
    
    init() {
        imageNames = (19...21).map{ "tomato\($0)" }
    }
    
    var body: some View {
        AnimatedImage(imageNames: imageNames, interval: 0.6)
    }
}
