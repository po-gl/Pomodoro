//
//  TaskLabel.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/10/23.
//

import SwiftUI

struct TaskLabel: View {
    var index: Int
    @ObservedObject var taskNotes: TaskNotes
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var presentingNoteOptions = false
    
    var body: some View {
        let text: String = index < taskNotes.tasks.count ? taskNotes.tasks[index] : ""
        AngledText(text)
            .accessibilityIdentifier("TaskLabel_\(text)")
            .accessibilityAddTraits(.isButton)
            .overlay(AngledLines(text))
        
            .onTapGesture {
                basicHaptic()
                presentingNoteOptions = true
            }
        
            .confirmationDialog("Task note options.", isPresented: $presentingNoteOptions) {
                Button(role: .destructive) {
                    resetHaptic()
                    withAnimation { taskNotes.tasks[index] = "" }
                } label: {
                    Text("Delete task")
                }
                .accessibilityIdentifier("DeleteTask")
            } message: {
                Text("Task: \(text)")
            }
        
            .opacity(text != "" ? 1.0 : 0.0)
            .animation(.easeInOut, value: taskNotes.tasks)
    }
    
    @ViewBuilder
    private func AngledText(_ text: String) -> some View {
        Text(text)
            .frame(width: 180, alignment: .leading)
            .offset(x: 90)
            .rotationEffect(.degrees(-45))
            .offset(y: -40)
            .opacity(text.isEmpty ? 0.0 : 1.0)
            .opacity(taskNotes.dragHasEnded ? 1.0 : 0.4)
            .opacity(index == pomoTimer.getIndex() || pomoTimer.isPaused ? 1.0 : 0.4)
            .animation(.easeInOut, value: taskNotes.dragHasEnded)
    }
    
    @ViewBuilder
    private func AngledLines(_ text: String) -> some View {
        Group {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .primary], startPoint: .leading, endPoint: .trailing))
                .frame(width: 20, height: 1)
                .rotationEffect(.degrees(-90))
                .offset(x: -7,y: -23)
            Rectangle()
                .frame(width: 10, height: 1)
                .offset(x: -5)
                .rotationEffect(.degrees(-45))
                .offset(y: -40)
        }
        .opacity(text.isEmpty ? 0.0 : 1.0)
        .opacity(taskNotes.dragHasEnded ? 1.0 : 0.4)
        .opacity(index == pomoTimer.getIndex() || pomoTimer.isPaused ? 1.0 : 0.4)
        .animation(.easeInOut, value: taskNotes.dragHasEnded)
    }
}

