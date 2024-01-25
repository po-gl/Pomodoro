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

    struct DraggableState {
        var offset = CGFloat.zero
        var pressed = false
    }

    @GestureState var dragState = DraggableState()

    @ObservedObject var disabled = ObservableValue(false)

    @State var zIndex = Double.zero

    var pressDuration = 0.5

    var draggableGesture: some Gesture {
        LongPressGesture(minimumDuration: pressDuration)
            .sequenced(before: DragGesture(minimumDistance: 0.0))
            .updating($dragState) { value, state, transaction in
                guard !disabled.value else { return }
                if !state.pressed {
                    state.pressed = true
                    swipeActionsDisabled.value = true
                    dismissSwipe()
                    Task { @MainActor in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }
                switch value {
                case .second(true, let event):
                    state.offset = event?.translation.height ?? .zero
                default:
                    break
                }
            }
            .onEnded { value in
                guard !disabled.value else { return }
                switch value {
                case .second(true, _):
                    swipeActionsDisabled.value = false
                default:
                    break
                }
            }
    }

    func body(content: Content) -> some View {
        content
            .offset(y: dragState.offset)
            .scaleEffect(dragState.pressed ? 1.06 : 1.0)
            .zIndex(dragState.pressed ? 999.0 : zIndex)
            .gesture(draggableGesture)

            .animation(.bouncy, value: dragState.offset)
            .animation(.easeInOut(duration: pressDuration), value: dragState.pressed)
    }
}
