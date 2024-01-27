//
//  VStackDraggable.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/24/24.
//

import SwiftUI

struct VStackDraggable: ViewModifier {
    @Environment(\.dismissSwipe) var dismissSwipe
    @Environment(\.swipeActionsDisabled) var swipeActionsDisabled

    @Environment(\.isReordering) var isReordering
    @Environment(\.selectedReorderingIndex) var selectedReorderingIndex
    @Environment(\.selectedReorderingRect) var selectedReorderingRect

    struct DraggableState {
        var offset = CGFloat.zero
        var pressed = false
    }

    @GestureState var dragState = DraggableState()

    @ObservedObject var disabled = ObservableValue(false)

    var index: Int = .zero
    var rect: CGRect = .zero
    var zIndex = Double.zero

    var pressDuration = 0.5

    var draggableGesture: some Gesture {
        LongPressGesture(minimumDuration: pressDuration)
            .sequenced(before: DragGesture(minimumDistance: 0.0))
            .updating($dragState) { value, state, transaction in
                guard !disabled.value else { return }
                if !state.pressed {
                    state.pressed = true
                    selectedReorderingIndex.value = index
                    isReordering.value = true

                    swipeActionsDisabled.value = true
                    dismissSwipe()

                    basicHaptic()
                    Task { @MainActor in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }
                switch value {
                case .second(true, let event):
                    state.offset = event?.translation.height ?? .zero
                    selectedReorderingRect.value = rect

                    // This is not a great solution for auto edge scrolling
                    if let taskListHeight = TaskListViewController.height {
                        if rect.minY < taskListHeight * 0.15 {
                            TaskListViewController.scrollUp()
                        } else if rect.maxY > taskListHeight * 0.85 {
                            TaskListViewController.scrollDown()
                        }
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                guard !disabled.value else { return }
                switch value {
                case .second(true, _):
                    isReordering.value = false
                    swipeActionsDisabled.value = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.1))
                        selectedReorderingIndex.value = -1
                        selectedReorderingRect.value = .zero
                    }
                default:
                    break
                }
            }
    }

    func body(content: Content) -> some View {
        content
            .offset(y: dragState.offset)
            .scaleEffect(dragState.pressed ? 1.08 : 1.0)
            .zIndex(dragState.pressed ? 999.0 : zIndex)
            .gesture(draggableGesture)

            .animation(.bouncy, value: dragState.offset)
            .animation(.easeInOut(duration: pressDuration), value: dragState.pressed)
    }
}
