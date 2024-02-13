//
//  TaskLabel.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/10/23.
//

import SwiftUI

struct TaskLabel: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.isOnBoarding) private var isOnBoarding

    var index: Int
    @ObservedObject var taskNotes: TasksOnBar
    @State var taskFromAdder: DraggableTask
    @Binding var draggableTask: DraggableTask

    var peekOffset = CGFloat.zero

    @EnvironmentObject var pomoTimer: PomoTimer

    @State var presentingNoteOptions = false
    @State var presentingNoteRename = false
    @State var renameText = ""

    @State var presentingTaskNoteInfo = false
    @State var selectedTaskNote: TaskNote?

    var text: String {
        index < taskNotes.tasksOnBar.count ? taskNotes.tasksOnBar[index] : ""
    }

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    var body: some View {
        GeometryReader { geometry in
            let text: String = index < taskNotes.tasksOnBar.count ? taskNotes.tasksOnBar[index] : ""
            AngledText(text: text, isBeingDragged: draggableTask.isDragging, peekOffset: peekOffset)
                .accessibilityIdentifier("TaskLabel_\(text)")
                .accessibilityAddTraits(.isButton)
                .overlay {
                    completedMark
                }

                .globalPosition(draggableTask.location ?? CGPoint(x: geometry.frame(in: .global).midX,
                                                                  y: geometry.frame(in: .global).midY))
                .draggableTask($draggableTask)
                .onChange(of: draggableTask.isDragging) {
                    draggableTask.dragHasEnded = !draggableTask.isDragging
                }
                .onChange(of: taskNotes.tasksOnBar) { _, tasksOnBar in
                    guard index < tasksOnBar.count else { return }
                    draggableTask.text = tasksOnBar[index]
                    setDraggableTaskStartLocation(geometry: geometry)
                }
                .onChange(of: pomoTimer.pomoCount) {
                    guard index < taskNotes.tasksOnBar.count else { return }
                    draggableTask.text = taskNotes.tasksOnBar[index]
                    setDraggableTaskStartLocation(geometry: geometry)
                }
                .onChange(of: draggableTask.text) {
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
                    if let taskNote = TasksData.taskInTodaysTasks(matching: text, context: viewContext),
                       let note = taskNote.note, note != "" {
                        Text("\(text)\n\(note)")
                    } else {
                        Text(text)
                    }
                }

                .alert("Rename Task Note", isPresented: $presentingNoteRename) {
                    renameAlertView
                }

                .sheet(isPresented: $presentingTaskNoteInfo) {
                    if let selectedTaskNote {
                        TaskInfoView(taskItem: selectedTaskNote, scrollToIdOnAppear: "estimate")
                    }
                }

                .opacity(text != "" ? 1.0 : 0.0)
                .animation(.easeInOut, value: taskNotes.tasksOnBar)
        }
    }

    private func setDraggableTaskStartLocation(geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        draggableTask.startLocation = CGPoint(x: frame.midX, y: frame.midY)
    }

    @ViewBuilder private var completedMark: some View {
        if let taskNote = TasksData.taskInTodaysTasks(matching: text, context: viewContext) {
            Image(systemName: "checkmark.circle", variableValue: 0.5)
                .symbolRenderingMode(.palette)
                .resizable()
                .frame(width: 15, height: 15)
                .offset(x: -16, y: -45)
                .foregroundStyle(.primary, .primary.opacity(0.8))
                .opacity(taskNote.completed ? 1.0 : 0.0)
                .animation(.spring, value: taskNote.completed)
        }
    }

    @ViewBuilder private var confirmationDialogButtons: some View {
        renameButton
        if text != "" {
            if let taskNote = TasksData.taskInTodaysTasks(matching: text, context: viewContext) {
                markAsCompletedButton(taskNote: taskNote)
                addEstimationButton(taskNote: taskNote)
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

    @ViewBuilder private func addEstimationButton(taskNote: TaskNote) -> some View {
        Button {
            basicHaptic()
            selectedTaskNote = taskNote
            presentingTaskNoteInfo = true
        } label: {
            Label("Add Pomodoro Estimation", systemImage: "questionmark.circle")
        }
    }

    @ViewBuilder private var addToTodayButton: some View {
        Button {
            basicHaptic()
            TasksData.addTask(text, order: 0, context: viewContext)
            TasksData.separateCompleted(todaysTasks, context: viewContext)
            NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .addedToList))
        } label: {
            Label("Add to Today's tasks", systemImage: "clock.arrow.circlepath")
        }
    }

    @ViewBuilder private var removeFromProgressBarButton: some View {
        Button(role: .destructive) {
            resetHaptic()
            Task { @MainActor in
                withAnimation { taskNotes.tasksOnBar[index] = "" }
                guard !isOnBoarding else { return }
                taskNotes.saveToUserDefaults()
            }
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
