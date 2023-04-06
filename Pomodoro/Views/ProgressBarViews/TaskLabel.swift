//
//  TaskLabel.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/10/23.
//

import SwiftUI

struct TaskLabel: View {
    var index: Int
    @ObservedObject var taskNotes: TasksOnBar
    @ObservedObject var taskFromAdder: DraggableTask
    
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var presentingNoteOptions = false
    
    var body: some View {
        let text: String = index < taskNotes.tasksOnBar.count ? taskNotes.tasksOnBar[index] : ""
        AngledText(text: text)
            .accessibilityIdentifier("TaskLabel_\(text)")
            .accessibilityAddTraits(.isButton)
        
            .opacity(taskFromAdder.dragHasEnded ? 1.0 : 0.4)
            .animation(.easeInOut, value: taskFromAdder.dragHasEnded)
            .opacity(index == pomoTimer.getIndex() || pomoTimer.isPaused ? 1.0 : 0.4)
        
            .onTapGesture {
                basicHaptic()
                presentingNoteOptions = true
            }
        
            .confirmationDialog("Task note options.", isPresented: $presentingNoteOptions) {
                Button(role: .destructive) {
                    resetHaptic()
                    withAnimation { taskNotes.tasksOnBar[index] = "" }
                    taskNotes.saveToUserDefaults()
                } label: {
                    Text("Remove from progress bar")
                }
                .accessibilityIdentifier("DeleteTask")
            } message: {
                Text("Task: \(text)")
            }
        
            .opacity(text != "" ? 1.0 : 0.0)
            .animation(.easeInOut, value: taskNotes.tasksOnBar)
    }
}

