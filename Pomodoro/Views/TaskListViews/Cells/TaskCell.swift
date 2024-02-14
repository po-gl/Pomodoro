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

    @State var scrollOnInputTask: Task<(), Never>?

    @FocusState var focus

    @State var showTaskInfo = false

    @State var deleted = false

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            TaskCheck(taskItem: taskItem, isAdderCell: isAdderCell, todaysTasks: todaysTasks)
            VStack(spacing: 5) {
                mainTextField
                if focus || !editNoteText.wrappedValue.isEmpty {
                    noteTextField
                }
            }
            TaskInfoCluster(taskItem: taskItem, showTaskInfo: $showTaskInfo, focus: _focus)
        }
        .opacity(deleted ? 0.0 : 1.0)
        .onChange(of: deleted) {
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
        .onDisappear {
            if !isAdderCell {
                deleteOrEditTask()
            } else {
                adderAction()
            }
        }

        .sheet(isPresented: $showTaskInfo) {
            TaskInfoView(taskItem: taskItem)
        }
        .onChange(of: showTaskInfo) {
            if isAdderCell && !showTaskInfo {
                focus = true
            }
        }

        .focused($focus)
        .onChange(of: focus) {
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

        .onChange(of: scenePhase) {
            if scenePhase == .background || scenePhase == .inactive {
                focus = false
            }
        }

        .swipeActions(edge: .leading) {
            if !isAdderCell {
                deleteTaskButton
                addToBarButton
            }
        }
        .swipeActions(edge: .trailing) {
            if !isAdderCell {
                if let timeStamp = taskItem.timestamp, timeStamp < Calendar.current.startOfDay(for: Date()) {
                    reAddToTodaysTasksButton
                    assignToTopProjectButton
                } else {
                    assignToTopProjectButton
                    flagTaskButton
                }
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
            .onChangeWithThrottle(of: editText.wrappedValue, for: 0.6) { _ in
                if focus {
                    scrollOnInput()
                }
            }
    }

    var noteTextField: some View {
        TextField("Add Note", text: editNoteText, axis: .vertical)
            .font(.footnote)
            .foregroundColor(.secondary)
            .onChangeWithThrottle(of: editNoteText.wrappedValue, for: 0.6) { _ in
                if focus {
                    scrollOnInput()
                }
            }
    }

    private func scrollOnInput() {
        scrollOnInputTask?.cancel()
        scrollOnInputTask = Task(priority: .utility) {
            try? await Task.sleep(for: .seconds(0.2))
            if !Task.isCancelled {
                TaskListViewController.focusedIndexPath = indexPath
                scrollTaskList()
            }
        }
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
                              pomosEstimate: taskItem.pomosEstimate,
                              pomosActual: taskItem.pomosActual,
                              order: taskItem.order,
                              date: Date.now-1,
                              projects: taskItem.projects as? Set<Project> ?? [],
                              context: viewContext)
            TasksData.separateCompleted(todaysTasks, context: viewContext)
            
            editText.wrappedValue = ""
            editNoteText.wrappedValue = ""
            taskItem.completed = false
            taskItem.pomosEstimate = -1
            taskItem.pomosActual = -1
            TasksData.edit("", note: "", flagged: false,
                           pomosEstimate: -1, pomosActual: -1,
                           projects: [], for: taskItem, context: viewContext)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                TaskListViewController.focusedIndexPath = indexPath
                scrollTaskList()
            }
        }
    }

    var infoSwipeButton: some View {
        Button(action: {
            basicHaptic()
            withAnimation { showTaskInfo = true }
        }, label: {
            Label("Details", systemImage: "info.circle")
        }).tint(Color(.lightGray))
    }

    var addToBarButton: some View {
        Button(action: {
            basicHaptic()
            TasksOnBar.shared.addTaskFromList(taskItem.text ?? "", context: viewContext)
            NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .addedToBar))
        }) {
            Label("Add to Bar", systemImage: "arrow.turn.up.left")
        }.tint(.end)
    }

    var deleteTaskButton: some View {
        Button(role: .destructive, action: {
            basicHaptic()
            deleted = true
            Task { @MainActor in
                TasksData.delete(taskItem, context: viewContext)
            }
        }) {
            Label("Delete", systemImage: "trash")
        }.tint(.red)
    }

    var assignToTopProjectButton: some View {
        Button(action: {
            basicHaptic()
            Task { @MainActor in
                if let project = ProjectsData.getTopProject(context: viewContext) {
                    if !taskItem.projectsArray.contains(project) {
                        TasksData.add(project: project, for: taskItem, context: viewContext)
                        NotificationCenter.default.post(name: .toast, object: Toast(message: project.name ?? "", action: .assignedProject))
                    } else {
                        TasksData.remove(project: project, for: taskItem, context: viewContext)
                        NotificationCenter.default.post(name: .toast, object: Toast(message: project.name ?? "", action: .unassignedProject))
                    }
                }
            }
        }) {
            Label("Assign To Top Project", systemImage: "square.3.layers.3d.top.filled")
        }.tint(.barRest)
    }

    var flagTaskButton: some View {
        Button(action: {
            basicHaptic()
            Task { @MainActor in
                TasksData.toggleFlagged(for: taskItem, context: viewContext)
            }
        }) {
            Label(taskItem.flagged ? "Unflag" : "Flag",
                  systemImage: taskItem.flagged ? "flag.slash.fill" : "flag.fill")
        }.tint(.barWork)
    }

    var reAddToTodaysTasksButton: some View {
        Button(action: {
            basicHaptic()
            if let taskText = taskItem.text {
                guard !TasksData.todaysTasksContains(taskText, context: viewContext) else { return }
                Task { @MainActor in
                    TasksData.duplicate(taskItem,
                                        completed: false,
                                        pomosEstimate: taskItem.pomosEstimate,
                                        pomosActual: -1,
                                        order: 0,
                                        date: Date().addingTimeInterval(-1),
                                        context: viewContext)
                    NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .reAdded))
                }
            }
        }) {
            Label("Re-add", systemImage: "arrow.uturn.up")
        }.tint(.blue)
    }
}

struct TaskCheck: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskItem: TaskNote

    var isAdderCell: Bool = false

    var todaysTasks: FetchedResults<TaskNote>? = nil

    let width: Double = 20
    let pi = Double.pi

    var body: some View {
        let radius = width/2
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1.2,
                                               miterLimit: 0,
                                               dash: !isAdderCell ? [] : [2, 2.0*pi*radius/14-2]))
                .opacity(taskItem.completed ? 1.0 : 0.5)
            Circle().frame(width: width/1.5)
                .opacity(taskItem.completed ? 1.0 : 0.0)
        }
        .foregroundColor(taskItem.completed ? .accent : .primary)
        .frame(width: width)
        .contentShape(Rectangle())
        .onTapGesture {
            basicHaptic()
            TasksData.toggleCompleted(for: taskItem, context: viewContext)

            if let todaysTasks, !isAdderCell {
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
}

struct TaskInfoCluster: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var taskItem: TaskNote

    var isAdderCell: Bool = false

    @Binding var showTaskInfo: Bool

    @FocusState var focus

    var body: some View {
        HStack(spacing: focus ? 2 : 5) {
            if taskItem.flagged {
                flag
            }
            pomosActualOrEstimate
            projectIndicators
                .offset(y: 2)
            if focus {
                infoButton
                    .padding(.leading, 3)
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
            .offset(y: projects.count == 1 ? 5 : 0)
        }
    }

    @ViewBuilder var pomosActualOrEstimate: some View {
        let pomos: Int16 = taskItem.pomosActual >= 0 && taskItem.completed ? taskItem.pomosActual : taskItem.pomosEstimate
        let color: Color = taskItem.pomosActual >= 0 && taskItem.completed ? .end : .barRest
        if pomos >= 0 {
            Text("\(pomos)")
                .font(.system(size: 14.0))
                .fontDesign(.rounded)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .brightness(colorScheme == .dark ? 0.1 : -0.15)
                .saturation(colorScheme == .dark ? 0.9 : 1.1)
        }
    }

    var flag: some View {
        Image(systemName: "leaf.fill")
            .foregroundColor(.barWork)
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
        }).tint(Color.accent)
    }
}
