//
//  View+customSwipeActions.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/21/23.
//

import SwiftUI

extension View {
    func customSwipeActions(leadingButtonCount: Int,
                            trailingButtonCount: Int,
                            @ViewBuilder leading: () -> some View,
                            @ViewBuilder trailing: () -> some View,
                            disabled: Bool = false) -> some View {
        ModifiedContent(content: self,
                        modifier: CustomSwipeActionsModifier(leadingButtonCount: leadingButtonCount,
                                                             trailingButtonCount: trailingButtonCount,
                                                             leadingView: leading(),
                                                             trailingView: trailing(),
                                                             disabled: disabled))
    }
}

struct CustomSwipeActionsModifier<L: View, T: View>: ViewModifier {
    @Environment(\.dismissSwipe) var dismissSwipe
    @Environment(\.swipeActionsDisabled) var swipeActionsDisabled

    let leadingButtonCount: Int
    let trailingButtonCount: Int
    
    let leadingView: L
    let trailingView: T

    let disabled: Bool

    private let width: CGFloat = 70
    private let padding: CGFloat = 10
    private var size: CGFloat { width + padding }

    var safeLeadingBtnCount: Int { max(0, min(leadingButtonCount, 2)) }
    var safeTrailingBtnCount: Int { max(0, min(trailingButtonCount, 2)) }

    @State var offset = CGFloat.zero
    @State var endOffset = CGFloat.zero

    @State var gestureStarted = false
    @State var gestureEdge: HorizontalEdge?

    var bounds: ClosedRange<CGFloat> {
        switch gestureEdge {
        case .trailing:
            return (trailingStop - 20)...15
        case .leading:
            return -15...(leadingStop + 20)
        default:
            return (trailingStop - 20)...15
        }
    }
    var leadingStop: CGFloat { CGFloat(safeLeadingBtnCount) * size }
    var trailingStop: CGFloat { -CGFloat(safeTrailingBtnCount) * size }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 25, coordinateSpace: .local)
            .onChanged { event in
                guard !disabled && !swipeActionsDisabled.value else { return }
                if !gestureStarted {
                    gestureStarted = true
                    dismissSwipe()
                    Task { @MainActor in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }

                if gestureEdge == nil && abs(event.translation.width) > 10 {
                    gestureEdge = event.translation.width < 0 ? .trailing : .leading
                }

                withAnimation {
                    let lower = bounds.lowerBound - endOffset
                    let upper = bounds.upperBound - endOffset
                    offset = max(lower, min(event.translation.width, upper))
                    offset += endOffset
                }
            }
            .onEnded { _ in
                guard !disabled && !swipeActionsDisabled.value else { return }
                let stop = gestureEdge == .trailing ? trailingStop : leadingStop
                gestureStarted = false
                withAnimation {
                    if abs(offset) > size {
                        offset = stop
                        endOffset = offset
                    } else {
                        resetGesture()
                    }
                }
            }
    }
    
    var onTapGesture: some Gesture {
        TapGesture()
            .onEnded {
                withAnimation(.easeInOut(duration: 0.2)) {
                    resetGesture()
                }
            }
    }
    
    func resetGesture() {
        offset = 0
        gestureEdge = nil
        endOffset = 0
    }

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .simultaneousGesture(dragGesture)
            .onChange(of: disabled) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    resetGesture()
                }
            }
            .onChange(of: swipeActionsDisabled.value) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    resetGesture()
                }
            }
            .onReceive(dismissSwipe.signal) {
                guard !gestureStarted else { return }
                withAnimation {
                    resetGesture()
                }
            }
            .background(alignment: .leading) {
                let countOffset = size * CGFloat(leadingButtonCount-1)
                let actionOffset: CGFloat = min(offset - size, bounds.upperBound - size) - countOffset
                HStack(spacing: 10) {
                    leadingView
                }
                .buttonStyle(SwipeStyle(width: width))
                .simultaneousGesture(dragGesture)
                .simultaneousGesture(onTapGesture)
                .offset(x: actionOffset)
                .opacity(abs(offset)/100.0)
            }
            .background(alignment: .trailing) {
                let countOffset = size * CGFloat(trailingButtonCount-1)
                let actionOffset: CGFloat = max(offset + size, bounds.lowerBound + size) + countOffset
                HStack(spacing: 10) {
                    trailingView
                }
                .buttonStyle(SwipeStyle(width: width))
                .simultaneousGesture(dragGesture)
                .simultaneousGesture(onTapGesture)
                .offset(x: actionOffset)
                .opacity(abs(offset)/100.0)
            }
    }
}
