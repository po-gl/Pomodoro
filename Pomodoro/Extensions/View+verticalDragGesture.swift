//
//  View+verticalDragGesture.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/11/23.
//

import SwiftUI
import Combine

extension View {
    func verticalDragGesture(offset: Binding<CGFloat>,
                             metalOffset: Binding<CGFloat>,
                             clampedTo: Range<CGFloat>? = nil,
                             onStart: @escaping () -> Void = {},
                             onEnd: @escaping () -> Void = {}) -> some View {
        ModifiedContent(content: self, modifier: VerticalDragGestureModifier(offset: offset,
                                                                             metalOffset: metalOffset,
                                                                             bounds: clampedTo,
                                                                             onStart: onStart,
                                                                             onEnd: onEnd))
    }
}

struct VerticalDragGestureModifier: ViewModifier {
    @Binding var offset: CGFloat
    /// Workaround due to metal views not updating for Transaction-based SwiftUI animations
    @Binding var metalOffset: CGFloat
    @State var metalOffsetAnimationTask: Task<(), Never>?
    let bounds: Range<CGFloat>?

    let onStart: () -> Void
    let onEnd: () -> Void

    @State var rawOffset: CGFloat = .zero
    @State var gestureStarted: Bool = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { event in
                        if !gestureStarted {
                            onStart()
                        }
                        gestureStarted = true
                        if let bounds {
                            rawOffset = max(bounds.lowerBound, min(event.translation.height, bounds.upperBound))
                        } else {
                            rawOffset = event.translation.height
                        }
                    }
                    .onEnded { _ in
                        onEnd()
                        withAnimation {
                            gestureStarted = false
                            offset = 0
                        }
                        animateMetalOffset(offset, duration: 0.2)
                    }
            )
            .onDisappear {
                offset = 0
                metalOffset = 0
                gestureStarted = false
            }
            .onChangeWithThrottle(of: rawOffset, for: .seconds(1.0 / 60.0)) { throttledOffset in
                withAnimation {
                    offset = throttledOffset
                }
                metalOffset = throttledOffset
            }
    }

    /// Animate metalOffset outside of the typical Transaction Animation api of SwiftUI
    /// Uses a basic cubic easeInOut function
    func animateMetalOffset(_ new: CGFloat, duration: TimeInterval) {
        let frameCount = duration / (1.0 / 60) // 60 fps
        let tick = (new - metalOffset) / frameCount;

        metalOffsetAnimationTask?.cancel()
        metalOffsetAnimationTask = Task { @MainActor in
            for _ in 0..<Int(frameCount) {
                try? await Task.sleep(for: .seconds(1.0 / 60.0))
                if !Task.isCancelled {
                    metalOffset += tick
                }
            }
        }
    }
}
