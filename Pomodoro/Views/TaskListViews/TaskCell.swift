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

    @State var editText: String
    @State var editNoteText: String

    var indexPath: IndexPath?

    // Set true if embedded in an info view and tapping text fields should
    // open the task's info page instead of editing text
    var isEmbedded: Bool? = false

    @FocusState var focus

    @State var showTaskInfo = false

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            check
            VStack(spacing: 5) {
                mainTextField
                    .frame(minHeight: 25)
                if focus || !editNoteText.isEmpty {
                    noteTextField
                }
            }
            .overrideAction(predicate: isEmbedded ?? false) {
                withAnimation { showTaskInfo = true }
            }
            HStack {
                if taskItem.flagged {
                    flag
                }
                projectIndicators
                    .offset(y: 2)
                if focus {
                    infoButton
                }
            }
        }

        .onAppear {
            focusIfJustAdded()
        }

        .sheet(isPresented: $showTaskInfo) {
            TaskInfoView(taskItem: taskItem)
        }
        .onChange(of: showTaskInfo) { _ in
            if !showTaskInfo {
                editText = taskItem.text!
                editNoteText = taskItem.note ?? ""
            }
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
            deleteTaskButton
            infoSwipeButton
        }
        .swipeActions(edge: .trailing) {
            if let timeStamp = taskItem.timestamp, timeStamp < Calendar.current.startOfDay(for: Date()) {
                reAddToTodaysTasksButton
            } else {
                flagTaskButton
            }
            assignToTopProjectButton
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
                editText = ""
                editNoteText = ""
                focus = true
            }
        }
    }

    var mainTextField: some View {
        TextField("", text: $editText, axis: .vertical)
            .foregroundColor(taskItem.timestamp?.isToday() ?? true ? .primary : .secondary)
            .onSubmitWithVerticalText(with: $editText) {
                if !editText.isEmpty {
                    Task {
                        try? await Task.sleep(for: .seconds(0.1))
                        TasksData.addTask("", order: taskItem.order, context: viewContext)
                        TasksData.separateCompleted(todaysTasks, context: viewContext)
                    }
                }
            }
    }

    var noteTextField: some View {
        TextField("Add Note", text: $editNoteText, axis: .vertical)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func deleteOrEditTask() {
        if editText.isEmpty {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        } else {
            TasksData.edit(editText, note: editNoteText, for: taskItem, context: viewContext)
        }
    }

    @ViewBuilder var check: some View {
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

    @ViewBuilder var projectIndicators: some View {
        let projects = Array(taskItem.projectsArray.prefix(4))
        let count = taskItem.projectsArray.count
        if count > 0 {
            WrappingHStack(models: projects, horizontalSpacing: 1.2, verticalSpacing: 1.2) { project in
                TinyProjectTag(color: Color(project.color ?? ""), size: 8)
            }
            .frame(width: 25, height: count > 2 ? 20 : 10, alignment: .top)
            .rotationEffect(.degrees(90))
            .frame(width: count > 2 ? 20 : 10, height: 25)
        }
    }

    var flag: some View {
        Image(systemName: "leaf.fill")
            .foregroundColor(Color("BarWork"))
            .frame(width: 20, height: 20)
    }

    var infoButton: some View {
        Button(action: {
            TasksData.edit(editText, note: editNoteText, for: taskItem, context: viewContext)
            focus = false
            withAnimation { showTaskInfo = true }
        }, label: {
            Image(systemName: "info.circle")
                .font(.title3)
        }).tint(Color("AccentColor"))
    }

    var infoSwipeButton: some View {
        Button(action: {
            withAnimation { showTaskInfo = true }
        }, label: {
            Label("Details", systemImage: "info.circle")
        }).tint(Color(.lightGray))
    }

    var deleteTaskButton: some View {
        Button(role: .destructive, action: {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        }) {
            Label("Delete", systemImage: "trash")
        }.tint(.red)
    }

    var assignToTopProjectButton: some View {
        Button(action: {
            Task {
                if let project = ProjectsData.getTopProject(context: viewContext) {
                    if !taskItem.projectsArray.contains(project) {
                        withAnimation { TasksData.add(project: project, for: taskItem, context: viewContext) }
                    } else {
                        withAnimation { TasksData.remove(project: project, for: taskItem, context: viewContext) }
                    }
                }
            }
        }) {
            Label("Assign To Top Project", systemImage: "square.3.layers.3d.top.filled")
        }.tint(Color("BarRest"))
    }

    var flagTaskButton: some View {
        Button(action: {
            withAnimation { TasksData.toggleFlagged(for: taskItem, context: viewContext) }
        }) {
            Label(taskItem.flagged ? "Unflag" : "Flag",
                  systemImage: taskItem.flagged ? "flag.slash.fill" : "flag.fill")
        }.tint(Color("BarWork"))
    }

    var reAddToTodaysTasksButton: some View {
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
