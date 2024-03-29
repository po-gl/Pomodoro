//
//  View+draggableTask.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/23.
//

import SwiftUI

extension View {
    func draggableTask(_ draggableTask: Binding<DraggableTask>) -> some View {
        ModifiedContent(content: self, modifier: DraggableTaskModifier(task: draggableTask))
    }
}

struct DraggableTaskModifier: ViewModifier {
    @Binding var task: DraggableTask

    @GestureState var gestureStartLocation: CGPoint?
    @GestureState var isDragging = false

    func body(content: Content) -> some View {
        content
            .gesture(dragGesture)
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { event in
                guard !task.text.isEmpty else { return }

                var newLocation = gestureStartLocation ?? task.location ?? task.startLocation ?? CGPoint()
                newLocation.x += event.translation.width
                newLocation.y += event.translation.height
                task.location = newLocation

                Task { @MainActor in
                    task.dragHasEnded = false
                }
            }
            .updating($gestureStartLocation) { _, startLocation, _ in
                startLocation = startLocation ?? task.location
            }
            .onEnded { _ in
                Task { @MainActor in
                    task.isDragging = false
                    task.dragHasEnded = true
                    // wait so location isn't reset immediately on end
                    try? await Task.sleep(for: .seconds(0.1))

                    withAnimation {
                        task.location = nil
                    }
                }
            }
            .updating($isDragging) { _, isDragging, _ in
                let drag = isDragging
                Task { @MainActor in
                    task.isDragging = drag
                    task.dragHasEnded = !drag
                }

                guard !task.text.isEmpty else { return }
                if !isDragging { basicHaptic() }
                isDragging = true
            }
    }
}
