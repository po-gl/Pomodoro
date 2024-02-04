//
//  View+pulseOnAppear.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/4/24.
//

import SwiftUI
import OSLog

extension View {
    func pulseOnAppear(if conditional: Bool = true) -> some View {
        ModifiedContent(content: self, modifier: PulseOnAppearModifier(conditional: conditional))
    }
}

struct PulseOnAppearModifier: ViewModifier {
    var conditional: Bool

    let duration = 0.8
    let hold = 0.2
    @State var pulsed = false

    func body(content: Content) -> some View {
        if conditional {
            content
                .overlay() {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.end)
                        .opacity(pulsed ? 0.3 : 0.0)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: duration), value: pulsed)
                }
                .onAppear {
                    Task { @MainActor in
                        pulsed = true
                        do {
                            try await Task.sleep(for: .seconds(duration + hold))
                            pulsed = false
                        } catch {
                            pulsed = false
                            Logger().error("Error sleeping: \(error.localizedDescription)")
                        }
                    }
                }
        } else {
            content
        }
    }
}
