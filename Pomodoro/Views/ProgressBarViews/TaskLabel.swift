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
    @State var taskFromAdder: DraggableTask
    @Binding var draggableTask: DraggableTask

    @EnvironmentObject var pomoTimer: PomoTimer

    @State var presentingNoteOptions = false
    @State var presentingNoteRename = false
    @State var renameText = ""

    var text: String {
        index < taskNotes.tasksOnBar.count ? taskNotes.tasksOnBar[index] : ""
    }

    var body: some View {
        GeometryReader { geometry in
            let text: String = index < taskNotes.tasksOnBar.count ? taskNotes.tasksOnBar[index] : ""
            AngledText(text: text, isBeingDragged: draggableTask.isDragging)
                .accessibilityIdentifier("TaskLabel_\(text)")
                .accessibilityAddTraits(.isButton)

                .globalPosition(draggableTask.location ?? CGPoint(x: geometry.frame(in: .global).midX,
                                                                  y: geometry.frame(in: .global).midY))
                .draggableTask($draggableTask)
                .onChange(of: draggableTask.isDragging) { _ in
                    draggableTask.dragHasEnded = !draggableTask.isDragging
                }
                .onChange(of: taskNotes.tasksOnBar) { tasksOnBar in
                    guard index < tasksOnBar.count else { return }
                    draggableTask.text = tasksOnBar[index]
                    setDraggableTaskStartLocation(geometry: geometry)
                }
                .onChange(of: pomoTimer.pomoCount) { _ in
                    guard index < taskNotes.tasksOnBar.count else { return }
                    draggableTask.text = taskNotes.tasksOnBar[index]
                    setDraggableTaskStartLocation(geometry: geometry)
                }
                .onChange(of: draggableTask.text) { _ in
                    setDraggableTaskStartLocation(geometry: geometry)
                }

                .opacity(taskFromAdder.dragHasEnded ? 1.0 : 0.4)
                .animation(.easeInOut, value: taskFromAdder.dragHasEnded)
                .opacity(index == pomoTimer.getIndex() || pomoTimer.isPaused ? 1.0 : 0.4)

                .onTapGesture {
                    basicHaptic()
                    presentingNoteOptions = true
                }

                .confirmationDialog("Task note options.", isPresented: $presentingNoteOptions) {
                    confirmationDialogButtons
                } message: {
                    Text(text)
                }

                .alert("Rename Task Note", isPresented: $presentingNoteRename) {
                    renameAlertView
                }

                .opacity(text != "" ? 1.0 : 0.0)
                .animation(.easeInOut, value: taskNotes.tasksOnBar)
        }
    }

    private func setDraggableTaskStartLocation(geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        draggableTask.startLocation = CGPoint(x: frame.midX, y: frame.midY)
    }

    @ViewBuilder private var confirmationDialogButtons: some View {
        renameButton
        if text != "" {
            if let taskNote = TasksData.taskInTodaysTasks(matching: text, context: viewContext) {
                markAsCompletedButton(taskNote: taskNote)
            } else {
                addToTodayButton
            }
        }
        removeFromProgressBarButton
    }

    @ViewBuilder private var renameButton: some View {
        Button {
            basicHaptic()
            renameText = text
            presentingNoteRename = true
        } label: {
            Label("Rename", systemImage: "pencil.line")
        }
    }

    @ViewBuilder private func markAsCompletedButton(taskNote: TaskNote) -> some View {
        Button {
            basicHaptic()
            TasksData.toggleCompleted(for: taskNote, context: viewContext)
        } label: {
            if taskNote.completed {
                Label("Mark as Not Completed", systemImage: "circle.slash")
            } else {
                Label("Mark as Completed", systemImage: "checkmark.circle")
            }
        }
    }

    @ViewBuilder private var addToTodayButton: some View {
        Button {
            basicHaptic()
            TasksData.addTask(text, order: -1, context: viewContext)
        } label: {
            Label("Add to Today's tasks", systemImage: "clock.arrow.circlepath")
        }
    }

    @ViewBuilder private var removeFromProgressBarButton: some View {
        Button(role: .destructive) {
            resetHaptic()
            withAnimation { taskNotes.tasksOnBar[index] = "" }
            taskNotes.saveToUserDefaults()
        } label: {
            Label("Remove from progress bar", systemImage: "trash")
        }
        .accessibilityIdentifier("DeleteTask")
    }

    @ViewBuilder private var renameAlertView: some View {
        TextField("", text: $renameText)
            // Select whole text immediately
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument,
                                                                      to: textField.endOfDocument)
                }
            }

        Button("Cancel", role: .cancel) {}
        Button("Save") {
            basicHaptic()
            taskNotes.renameTask(renameText, index: index, context: viewContext)
        }
    }
}
