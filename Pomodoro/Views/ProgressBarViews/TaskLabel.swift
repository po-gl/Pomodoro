//
//  TaskLabel.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/10/23.
//

import SwiftUI

struct TaskLabel: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var index: Int
    @ObservedObject var taskNotes: TasksOnBar
    @ObservedObject var taskFromAdder: DraggableTask
    
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var presentingNoteOptions = false
    @State var presentingNoteRename = false
    @State var renameText = ""
    
    
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
                ConfirmationDialogButtons()
            } message: {
                Text(text)
            }
        
            .alert("Rename Task Note", isPresented: $presentingNoteRename) {
                AlertView()
            }
        
            .opacity(text != "" ? 1.0 : 0.0)
            .animation(.easeInOut, value: taskNotes.tasksOnBar)
    }
    
    
    @ViewBuilder
    private func ConfirmationDialogButtons() -> some View {
        let text: String = index < taskNotes.tasksOnBar.count ? taskNotes.tasksOnBar[index] : ""
        
        Button() {
            basicHaptic()
            renameText = text
            presentingNoteRename = true
        } label: {
            Label("Rename", systemImage: "pencil.line")
        }
        
        if text != "" && !TasksData.todaysTasksContains(text, context: viewContext) {
            Button() {
                basicHaptic()
                TasksData.addTask(text, order: -1, context: viewContext)
            } label: {
                Label("Add to Today's tasks", systemImage: "clock.arrow.circlepath")
            }
        }
        
        Button(role: .destructive) {
            resetHaptic()
            withAnimation { taskNotes.tasksOnBar[index] = "" }
            taskNotes.saveToUserDefaults()
        } label: {
            Label("Remove from progress bar", systemImage: "trash")
        }
        .accessibilityIdentifier("DeleteTask")
    }
    
    
    @ViewBuilder
    private func AlertView() -> some View {
        TextField("" , text: $renameText)
            // Select whole text immediately
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                }
            }
        
        Button("Cancel", role: .cancel) {}
        Button("Save") {
            basicHaptic()
            taskNotes.renameTask(renameText, index: index, context: viewContext)
        }
    }
}

