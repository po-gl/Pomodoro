//
//  View+verticalDragGesture.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/11/23.
//

import SwiftUI

extension View {
    func verticalDragGesture(offset: Binding<CGFloat>, clampedTo: Range<CGFloat>? = nil) -> some View {
        ModifiedContent(content: self, modifier: VerticalDragGestureModifier(offset: offset, bounds: clampedTo))
    }
}

struct VerticalDragGestureModifier: ViewModifier {
    @Binding var offset: CGFloat
    let bounds: Range<CGFloat>?

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { event in
                        withAnimation {
                            if let bounds {
                                offset = max(bounds.lowerBound, min(event.translation.height, bounds.upperBound))
                            } else {
                                offset = event.translation.height
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation {
                            offset = 0
                        }
                    }
            )
    }
}
