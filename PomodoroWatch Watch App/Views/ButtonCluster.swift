//
//  ButtonCluster.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/24/22.
//

import Foundation
import SwiftUI

struct ButtonCluster: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @EnvironmentObject var pomoTimer: PomoTimer

    var body: some View {
        HStack {
            ResetButton
            Spacer()
            StartStopButton
        }
    }

    @ViewBuilder private var ResetButton: some View {
        let isEnabled = pomoTimer.isPaused || pomoTimer.getStatus() == .end
        Image(systemName: withFill("arrow.counterclockwise.circle"))
            .accessibilityIdentifier("resetButton")
            .foregroundColor(pomoTimer.isPaused ? .orange : Color(hex: 0x333333))
            .overlay(softLightOverlay)
            .font(.system(size: 40))
            .onTapGesture {
                guard isEnabled else { return }
                resetHaptic()
                pomoTimer.unpause() // to update crown scroll progress
                withAnimation(.easeIn(duration: 0.2)) {
                    pomoTimer.reset()
                    pomoTimer.pause()
                }
            }
            .disabled(!isEnabled)
    }

    @ViewBuilder private var StartStopButton: some View {
        let isEnabled = pomoTimer.getStatus() != .end
        Image(systemName: pomoTimer.isPaused ? withFill("play.circle") : withFill("pause.circle"))
            .accessibilityIdentifier("playPauseButton")
            .foregroundColor(.accentColor)
            .overlay(softLightOverlay)
            .font(.system(size: 40))
            .onTapGesture {
                guard isEnabled else { return }
                pomoTimer.isPaused ? startHaptic() : stopHaptic()
                withAnimation(.easeIn(duration: 0.2)) {
                    pomoTimer.toggle()
                }
            }
            .disabled(!isEnabled)
    }

    @State var showSoftLightOverlay = true

    @ViewBuilder private var softLightOverlay: some View {
        // In watchOS 10, blendMode abruptly reverts to normal when
        // luminance is reduced. So here I set the overlay opacity to
        // 0 and set the animation to nil, then delay the returning animation
        if #available(watchOS 10.0, *) {
            LinearGradient(colors: [.clear, .white], startPoint: .leading, endPoint: .trailing)
                .clipShape(Circle())
                .blendMode(.softLight)

                .opacity(isLuminanceReduced ? 0.0 : showSoftLightOverlay ? 1.0 : 0.0)
                .animation(nil, value: isLuminanceReduced)
                .onChange(of: isLuminanceReduced) { isLuminanceReduced in
                    if !isLuminanceReduced {
                        withAnimation(.default.delay(0.4)) {
                            showSoftLightOverlay = true
                        }
                    } else {
                        showSoftLightOverlay = false
                    }
                }

        } else {
            LinearGradient(colors: [.clear, .white], startPoint: .leading, endPoint: .trailing)
                .clipShape(Circle())
                .blendMode(.softLight)
        }
    }

    private func withFill(_ systemName: String) -> String {
        return isLuminanceReduced ? systemName : systemName + ".fill"
    }
}
