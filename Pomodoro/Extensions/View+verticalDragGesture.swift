//
//  View+verticalDragGesture.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/11/23.
//

import SwiftUI

extension View {
    func verticalDragGesture(offset: Binding<CGFloat>,
                             clampedTo: Range<CGFloat>? = nil,
                             onStart: @escaping () -> Void = {},
                             onEnd: @escaping () -> Void = {}) -> some View {
        ModifiedContent(content: self, modifier: VerticalDragGestureModifier(offset: offset,
                                                                             bounds: clampedTo,
                                                                             onStart: onStart,
                                                                             onEnd: onEnd))
    }
}

struct VerticalDragGestureModifier: ViewModifier {
    @Binding var offset: CGFloat
    let bounds: Range<CGFloat>?

    let onStart: () -> Void
    let onEnd: () -> Void

    @State var gestureStarted: Bool = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { event in
                        if !gestureStarted {
                            onStart()
                        }
                        withAnimation {
                            gestureStarted = true
                            if let bounds {
                                offset = max(bounds.lowerBound, min(event.translation.height, bounds.upperBound))
                            } else {
                                offset = event.translation.height
                            }
                        }
                    }
                    .onEnded { _ in
                        onEnd()
                        withAnimation {
                            gestureStarted = false
                            offset = 0
                        }
                    }
            )
    }
}
