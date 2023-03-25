//
//  AnimatedImage.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct AnimatedImage: View {
    @State private var image: Image?
    private let imageNames: [String]
    private let interval: Double
    private let loops: Bool
    
    @State private var timer: Timer?
    
    init(imageNames: [String], interval: Double = 0.1, loops: Bool = false) {
        self.imageNames = imageNames
        self.interval = interval
        self.loops = loops
    }
    
    var body: some View {
        VStack {
            image?
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
        .onAppear {
            animate()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func animate() {
        var imageIndex: Int = 0
        self.image = Image(self.imageNames[0])
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            self.image = Image(self.imageNames[imageIndex])
            imageIndex = (imageIndex+1) % self.imageNames.count
            
            if !self.loops && imageIndex == 0 {
                timer.invalidate()
            }
        }
    }
}

