//
//  TaskAdderView.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/9/23.
//

import SwiftUI

struct TaskAdderView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var taskFromAdder: DraggableTask
    
    var startLocation: CGPoint = CGPoint(x: 40, y: -20)
    
    @GestureState private var gestureStartLocation: CGPoint?
    @GestureState private var isDragging = false
    @FocusState private var taskFocus
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ZStack  {
                TaskInput()
                    .position(taskFromAdder.dragLocation ?? startLocation)
                TouchCircle()
                    .opacity(taskFromAdder.dragText.isEmpty ? 0.6 : 1.0)
                    .animation(.easeInOut, value: isDragging)
                    .position(taskFromAdder.dragLocation ?? startLocation)
                    .gesture(drag)
                
                DragHint()
                    .position(startLocation)
                    .offset(y: 24)
                    .opacity(taskFromAdder.dragText.isEmpty || isDragging ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 3), value: taskFromAdder.dragText.isEmpty)
                    .animation(.easeInOut(duration: 3), value: isDragging)
            }
            .frame(height: 50)
            .padding(.bottom, 60)
        }
        .frame(height: 0)
        .onChange(of: isDragging) { _ in
            taskFromAdder.dragHasEnded = !isDragging
        }
    }
    
    
    @ViewBuilder
    private func TaskInput() -> some View {
        TextField("Add task", text: $taskFromAdder.dragText)
            .accessibilityIdentifier("AddTask")
            .focused($taskFocus)
            .submitLabel(.done)
            .offset(x: 25)
            .rotationEffect(isDragging ? .degrees(-45) : .degrees(0), anchor: .leading)
            .shadow(radius: isDragging ? 5 : 0)
            .animation(.easeInOut, value: isDragging)
            .offset(x: 140)
            .frame(width: 280)
    }
    
    @ViewBuilder
    private func TouchCircle() -> some View {
        let width: Double = isDragging ? 15 : 25
        let strokeWidth: Double = 2
        let gap: Double = 10
        Circle()
            .strokeBorder(style: StrokeStyle(lineWidth: strokeWidth))
            .frame(width: width)
            .overlay(
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: strokeWidth))
                    .frame(width: width - gap)
            )
            .opacity(0.7)
            .accessibilityIdentifier("DraggableTask")
    }
    
    @ViewBuilder
    private func DragHint() -> some View {
        let gradient = LinearGradient(stops: [.init(color: .primary, location: 0.0),
                                              .init(color: .primary.opacity(0.3), location: 1.0)],
                                      startPoint: .leading, endPoint: .trailing)
        HStack (spacing: 14) {
            Image(systemName: "arrowshape.forward.fill")
                .foregroundStyle(gradient)
                .font(.system(size: 16))
                .rotationEffect(.degrees(90))
                .offset(y: 4)
                .opacity(animate ? colorScheme == .light ? 0.15 : 0.3 : 0.0)
            Text("Drag to bar")
                .font(.system(size: 14))
                .opacity(animate ? 0.4 : 0.0)
        }
        .onAppear {
            withAnimation (.easeInOut(duration: 3).repeatForever()) {
                animate = true
            }
        }
        .offset(x: 44)
        .frame(width: 160)
    }
    
    
    private var drag: some Gesture {
        DragGesture()
            .onChanged { event in
                guard !taskFromAdder.dragText.isEmpty else { return }
                
                var newLocation = gestureStartLocation ?? taskFromAdder.dragLocation ?? startLocation
                newLocation.x += event.translation.width
                newLocation.y += event.translation.height
                taskFromAdder.dragLocation = newLocation
            }
            .updating($gestureStartLocation) { _, startLocation, _ in
                startLocation = startLocation ?? taskFromAdder.dragLocation
            }
            .onEnded { _ in
                Task {
                    // wait so location isn't reset immediately on end
                    try? await Task.sleep(for: .seconds(0.1))
                    withAnimation {
                        taskFromAdder.dragLocation = startLocation
                    }
                }
            }
            .updating($isDragging) {_, isDragging, _ in
                guard !taskFromAdder.dragText.isEmpty else { return }
                if !isDragging { basicHaptic() }
                isDragging = true
                taskFocus = false
            }
    }
}
