//
//  TaskAdderView.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/9/23.
//

import SwiftUI

struct TaskAdderView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var taskFromAdder: DraggableTask

    var startLocation: CGPoint = CGPoint(x: 40, y: -20)

    @FocusState private var taskFocus

    @State private var animate = false
    @State private var showAutoComplete = false

    var body: some View {
        ZStack {
            ZStack {
                taskInput
                    .position(taskFromAdder.location ?? startLocation)
                touchCircle
                    .opacity(taskFromAdder.text.isEmpty ? 0.8 : 1.0)
                    .animation(.easeInOut, value: taskFromAdder.isDragging)
                    .animation(.easeInOut, value: taskFromAdder.text)
                    .position(taskFromAdder.location ?? startLocation)
                    .draggableTask($taskFromAdder)
                    .zIndex(1)

                dragHint
                    .position(startLocation)
                    .offset(y: 24)
                    .opacity(taskFromAdder.text.isEmpty || taskFromAdder.isDragging ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 3), value: taskFromAdder.text.isEmpty)
                    .animation(.easeInOut(duration: 3), value: taskFromAdder.isDragging)

                if showAutoComplete {
                    if #available(iOS 17, *) {
                        AutoCompleteView(text: $taskFromAdder.text)
                            .position(startLocation)
                            .offset(x: 153, y: -125)
                            .transition(BlurReplaceTransition(configuration: .downUp))
                    } else {
                        AutoCompleteView(text: $taskFromAdder.text)
                            .position(startLocation)
                            .offset(x: 153, y: -125)
                            .transition(.opacity)
                    }
                }
            }
            .frame(height: 50)
            .padding(.bottom, 60)
        }
        .frame(height: 0)
        .onAppear {
            taskFromAdder.startLocation = startLocation
        }

        .onChange(of: taskFromAdder.isDragging) { isDragging in
            taskFromAdder.dragHasEnded = !taskFromAdder.isDragging
            if isDragging {
                taskFocus = false
            }
        }

        .onChange(of: taskFocus) { focus in
            if focus {
                Task {
                    try? await Task.sleep(for: .seconds(0.2))
                    withAnimation {
                        showAutoComplete = true
                    }
                }
            } else {
                withAnimation {
                    showAutoComplete = false
                }
            }
        }
    }

    @ViewBuilder private var taskInput: some View {
        TextField("Add task", text: $taskFromAdder.text)
            .font(.system(.callout, design: .monospaced, weight: .medium))
            .accessibilityIdentifier("AddTask")
            .focused($taskFocus)
            .offset(x: 25)
            .rotationEffect(taskFromAdder.isDragging ? .degrees(-45) : .degrees(0), anchor: .leading)
            .shadow(radius: taskFromAdder.isDragging ? 5 : 0)
            .animation(.easeInOut, value: taskFromAdder.isDragging)
            .offset(x: 140)
            .frame(width: 280)
    }

    @ViewBuilder private var touchCircle: some View {
        let width: Double = taskFromAdder.isDragging ? 15 : 25
        let extraSize = CGSize(width: 5, height: 40)
        let strokeWidth: Double = 1.2
        let gap: Double = taskFromAdder.text.isEmpty ? 8 : 10
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: strokeWidth))
                    .frame(width: width)
                    .background(
                        Circle()
                            .opacity(0.25)
                            .frame(width: width - gap - strokeWidth)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: strokeWidth))
                            .frame(width: width - gap)
                    )
                    .opacity(0.7)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: width + extraSize.width, height: geometry.size.height + extraSize.height)
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
            .offset(x: -extraSize.width/2)
            .accessibilityIdentifier("DraggableTask")
        }
    }

    @ViewBuilder private var dragHint: some View {
        let gradient = LinearGradient(stops: [.init(color: .primary, location: 0.0),
                                              .init(color: .primary.opacity(0.3), location: 1.0)],
                                      startPoint: .leading, endPoint: .trailing)
        HStack(spacing: 14) {
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
            withAnimation(.easeInOut(duration: 3).repeatForever()) {
                animate = true
            }
        }
        .offset(x: 44)
        .frame(width: 160)
    }
}
