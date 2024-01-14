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
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var taskItem: TaskNote

    var editText: Binding<String> {
        Binding(get: { taskItem.text ?? "" },
                set: { newValue in taskItem.text = newValue })
    }
    var editNoteText: Binding<String> {
        Binding(get: { taskItem.note ?? "" },
                set: { newValue in taskItem.note = newValue })
    }

    var isAdderCell: Bool = false

    // Set true if embedded in an info view and tapping text fields should
    // open the task's info page instead of editing text
    var isEmbedded: Bool? = false

    var initialIndexPath: IndexPath?
    ///  Reliably gets the indexPath on reorderings where CellRegistration doesn't
    var indexPath: IndexPath? {
        guard let cell else { return initialIndexPath}
        return collectionView?.indexPath(for: cell) ?? initialIndexPath
    }
    // Only needed for indexPath
    var collectionView: UICollectionView?
    var cell: UICollectionViewCell?
    var scrollTaskList: () -> Void = {}

    @FocusState var focus

    @State var showTaskInfo = false

    @State var deleted = false

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            check
                .offset(y: 2)
            VStack(spacing: 5) {
                mainTextField
                    .frame(minHeight: 25)
                if focus || !editNoteText.wrappedValue.isEmpty {
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
        .opacity(deleted ? 0.0 : 1.0)
        .onChange(of: deleted) { deleted in
            // Since cells are reused, reset deleted property
            if deleted {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.5))
                    self.deleted = false
                }
            }
        }

        .onAppear {
            focusIfJustAdded()
        }

        .sheet(isPresented: $showTaskInfo) {
            TaskInfoView(taskItem: taskItem)
        }

        .focused($focus)
        .onChange(of: focus) { _ in
            if focus {
                TaskListViewController.focusedIndexPath = indexPath
            } else if !showTaskInfo {
                TaskListViewController.focusedIndexPath = nil
                if !isAdderCell {
                    deleteOrEditTask()
                } else {
                    adderAction()
                }
            }
        }
        .onReceive(Publishers.focusOnAdder) { _ in
            if isAdderCell {
                focus = true
            }
        }

        .doneButton(isPresented: focus)

        .onChange(of: scenePhase) { scenePhase in
            if scenePhase == .background || scenePhase == .inactive {
                focus = false
            }
        }

        .swipeActions(edge: .leading) {
            if !isAdderCell {
                deleteTaskButton
                infoSwipeButton
            }
        }
        .swipeActions(edge: .trailing) {
            if !isAdderCell {
                if let timeStamp = taskItem.timestamp, timeStamp < Calendar.current.startOfDay(for: Date()) {
                    reAddToTodaysTasksButton
                } else {
                    flagTaskButton
                }
                assignToTopProjectButton
            }
        }
    }

    private func focusIfJustAdded() {
        if let date = taskItem.timestamp {
            if Date.now.timeIntervalSince(date) < 0.5 {
                editText.wrappedValue = ""
                editNoteText.wrappedValue = ""
                focus = true
            }
        }
    }

    var mainTextField: some View {
        TextField("", text: editText, axis: .vertical)
            .foregroundColor(taskItem.timestamp?.isToday() ?? true ? .primary : .secondary)
            .onSubmitWithVerticalText(with: editText, resigns: !isAdderCell) {
                if !isAdderCell {
                    if !editText.wrappedValue.isEmpty && taskItem.timestamp?.isToday() ?? false {
                        Task {
                            try? await Task.sleep(for: .seconds(0.1))
                            TasksData.addTask("", order: taskItem.order, context: viewContext)
                            TasksData.separateCompleted(todaysTasks, context: viewContext)
                        }
                    }
                } else {
                    adderAction()
                }
            }
    }

    var noteTextField: some View {
        TextField("Add Note", text: editNoteText, axis: .vertical)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func deleteOrEditTask() {
        if editText.wrappedValue.isEmpty {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        } else {
            TasksData.saveContext(viewContext, errorMessage: "Saving task cell")
        }
    }

    private func adderAction() {
        if !editText.wrappedValue.isEmpty && !showTaskInfo {
            TasksData.addTask(editText.wrappedValue,
                              note: editNoteText.wrappedValue,
                              completed: taskItem.completed,
                              flagged: taskItem.flagged,
                              order: taskItem.order,
                              date: Date.now-1,
                              projects: taskItem.projects as? Set<Project> ?? [],
                              context: viewContext)
            TasksData.separateCompleted(todaysTasks, context: viewContext)
            
            editText.wrappedValue = ""
            editNoteText.wrappedValue = ""
            taskItem.completed = false
            TasksData.edit("", note: "", flagged: false, projects: [], for: taskItem, context: viewContext)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                TaskListViewController.focusedIndexPath = indexPath
                scrollTaskList()
            }
        }
    }

    @ViewBuilder var check: some View {
        let width: Double = 20
        let radius = width/2
        let pi = Double.pi
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1.2,
                                               miterLimit: 0,
                                               dash: !isAdderCell ? [] : [2, 2.0*pi*radius/14-2]))
                .opacity(taskItem.completed ? 1.0 : 0.5)
            Circle().frame(width: width/1.5)
                .opacity(taskItem.completed ? 1.0 : 0.0)
        }
        .foregroundColor(taskItem.completed ? Color("AccentColor") : .primary)
        .frame(width: width)
        .onTapGesture {
            basicHaptic()
            TasksData.toggleCompleted(for: taskItem, context: viewContext)

            if !isAdderCell {
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
            if !isAdderCell {
                TasksData.saveContext(viewContext, errorMessage: "Saving task cell")
                focus = false
                withAnimation { showTaskInfo = true }
            } else {
                TasksData.saveContext(viewContext, errorMessage: "Saving task cell")
                withAnimation { showTaskInfo = true }
            }
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
            deleted = true
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
                withAnimation {
                    TasksData.duplicate(taskItem,
                                        completed: false,
                                        order: 0,
                                        date: Date().addingTimeInterval(-1),
                                        context: viewContext)
                }
            }
        }) {
            Label("Re-add", systemImage: "arrow.uturn.up")
        }.tint(.blue)
    }
}
