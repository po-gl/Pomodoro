//
//  AnimatedImage.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct AnimatedImageData: Equatable {
    var imageNames: [String]
    var interval = 0.1
    var loops = false
}

struct AnimatedImage: View {
    var data: AnimatedImageData

    @State private var image: Image?
    @State private var timer: Timer?

    var body: some View {
        VStack {
            image?
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
        .onAppear {
            animate(images: data.imageNames, interval: data.interval, loops: data.loops)
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: data) {
            animate(images: data.imageNames, interval: data.interval, loops: data.loops)
        }
    }

    private func animate(images: [String], interval: Double, loops: Bool) {
        var imageIndex: Int = 0
        let imageViews = images.map { Image($0) }
        image = imageViews.first

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            image = imageViews[imageIndex]
            imageIndex = (imageIndex+1) % imageViews.count

            if !loops && imageIndex == 0 {
                timer.invalidate()
            }
        }
    }
}
