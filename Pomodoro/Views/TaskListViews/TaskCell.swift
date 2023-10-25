//
//  TaskCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct TaskCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskItem: TaskNote

    let indexPath: IndexPath

    @State var editText = ""
    @State var editNoteText = ""
    @FocusState var focus

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            check()
            VStack(spacing: 5) {
                mainTextField()
                    .frame(minHeight: 25)
                if focus || !editNoteText.isEmpty {
                    noteTextField()
                }
            }
            if taskItem.flagged {
                flag()
            }
        }

        .onAppear {
            editText = taskItem.text!
            editNoteText = taskItem.note ?? ""

            focusIfJustAdded()
        }

        .focused($focus)
        .onChange(of: focus) { _ in
            if focus {
                TaskListViewController.focusedIndexPath = indexPath
            } else {
                TaskListViewController.focusedIndexPath = nil
                deleteOrEditTask()
            }
        }
        .doneButton(isPresented: focus)

        .swipeActions(edge: .leading) {
            deleteTaskButton()
        }
        .swipeActions(edge: .trailing) {
            if let timeStamp = taskItem.timestamp, timeStamp < Calendar.current.startOfDay(for: Date()) {
                reAddToTodaysTasksButton()
            }
            flagTaskButton()
        }

        .onChange(of: taskItem.completed) { _ in
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                withAnimation {
                    viewContext.undoManager?.disableUndoRegistration()
                    TasksData.separateCompleted(todaysTasks, context: viewContext)
                    viewContext.undoManager?.enableUndoRegistration()
                }
            }
        }
    }

    private func focusIfJustAdded() {
        if let date = taskItem.timestamp {
            if Date.now.timeIntervalSince(date) < 0.5 {
                focus = true
            }
        }
    }

    @ViewBuilder
    private func mainTextField() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .foregroundColor(taskItem.timestamp?.isToday() ?? true ? .primary : .secondary)
            .onSubmitWithVerticalText(with: $editText) {
                deleteOrEditTask()

                if !editText.isEmpty {
                    TasksData.addTask("", context: viewContext)
                }
            }
    }

    @ViewBuilder
    private func noteTextField() -> some View {
        TextField("Add Note", text: $editNoteText, axis: .vertical)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func deleteOrEditTask() {
        if editText.isEmpty {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        } else {
            TasksData.editText(editText, note: editNoteText, for: taskItem, context: viewContext)
        }
    }

    @ViewBuilder
    private func check() -> some View {
        let width: Double = 20
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1.2))
                .opacity(taskItem.completed ? 1.0 : 0.5)
            Circle().frame(width: width/1.5)
                .opacity(taskItem.completed ? 1.0 : 0.0)
        }
        .foregroundColor(taskItem.completed ? Color("AccentColor") : .primary)
        .frame(width: width)
        .onTapGesture {
            basicHaptic()
            TasksData.toggleCompleted(for: taskItem, context: viewContext)
        }
    }

    @ViewBuilder
    private func flag() -> some View {
        Image(systemName: "leaf.fill")
            .foregroundColor(Color("BarWork"))
            .frame(width: 20, height: 20)
    }

    @ViewBuilder
    private func deleteTaskButton() -> some View {
        Button(role: .destructive, action: {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        }) {
            Label("Delete", systemImage: "trash")
        }.tint(.red)
    }

    @ViewBuilder
    private func flagTaskButton() -> some View {
        Button(action: {
            withAnimation { TasksData.toggleFlagged(for: taskItem, context: viewContext) }
        }) {
            Label(taskItem.flagged ? "Unflag" : "Flag",
                  systemImage: taskItem.flagged ? "flag.slash.fill" : "flag.fill")
        }.tint(Color("BarWork"))
    }

    @ViewBuilder
    private func reAddToTodaysTasksButton() -> some View {
        Button(action: {
            if let taskText = taskItem.text {
                guard !TasksData.todaysTasksContains(taskText, context: viewContext) else { return }
                withAnimation { TasksData.addTask(taskText,
                                                  note: taskItem.note ?? "",
                                                  flagged: taskItem.flagged,
                                                  date: Date().addingTimeInterval(-1),
                                                  context: viewContext) }
            }
        }) {
            Label("Re-add", systemImage: "arrow.uturn.up")
        }.tint(.blue)
    }
}
