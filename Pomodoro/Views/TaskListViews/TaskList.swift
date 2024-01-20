//
//  TaskList.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/23.
//

import SwiftUI

struct TaskList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var errors = Errors.shared

    @State var showingArchivedProjects = false
    @AppStorage("showProjects") var showProjects = true
    @AppStorage("showPastTasks") var showPastTasks = true

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    @FetchRequest(fetchRequest: TasksData.limitedPastTasksRequest)
    var limitedPastTasks: FetchedResults<TaskNote>

    @AppStorage("hasShownError") var hasShownError = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                TaskListCollectionView(showProjects: showProjects,
                                       showPastTasks: showPastTasks)
                .ignoresSafeArea(.keyboard)
                
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea(edges: .vertical)
                .navigationTitle("Task List")
                
                .toolbar {
                    Menu {
                        showArchivedProjectsButton
                        Divider()
                        showProjectsButton
                        showPastTasksButton
                        Divider()
                        markTodaysTasksAsDoneButton
                        addUnfinishedTasksButton
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .navigationDestination(isPresented: $showingArchivedProjects) {
                        ArchivedProjectsView()
                    }
                }
                
                .toolbar {
                    if let coreDataError = errors.coreDataError {
                        ErrorView(pomoError: Errors.coreDataPomoError,
                                  nsError: coreDataError,
                                  showImmediately: !hasShownError)
                    }
                }
                .onChange(of: errors.coreDataError) { error in
                    guard error != nil else { return }
                    Task {
                        try? await Task.sleep(for: .seconds(0.5))
                        hasShownError = true
                    }
                }
                
                focusNewTaskButton
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .ignoresSafeArea(.keyboard)
        }
        .tint(Color("NavigationAccent"))
    }

    @ViewBuilder private var focusNewTaskButton: some View {
        Button(action: {
            basicHaptic()
            NotificationCenter.default.post(name: .focusOnAdder, object: nil)
        }) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 23, height: 23)
                Text("New Task")
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .padding(.trailing, 2)
            }
            .frame(height: 23)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .foregroundStyle(Color("AccentColor"))
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .brightness(colorScheme == .dark ? -0.06 : 0.012)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var showArchivedProjectsButton: some View {
        Button(action: {
            basicHaptic()
            showingArchivedProjects = true
        }) {
            Label("Archived Projects", systemImage: "archivebox")
        }
    }

    @ViewBuilder private var showProjectsButton: some View {
        Button(action: {
            basicHaptic()
            withAnimation { showProjects.toggle() }
        }) {
            if showProjects {
                Label("Hide Projects", systemImage: "eye.slash.fill")
            } else {
                Label("Show Projects", systemImage: "eye.fill")
            }
        }
    }

    @ViewBuilder private var showPastTasksButton: some View {
        Button(action: {
            basicHaptic()
            withAnimation { showPastTasks.toggle() }
        }) {
            if showPastTasks {
                Label("Hide Past Tasks", systemImage: "eye.slash")
            } else {
                Label("Show Past Tasks", systemImage: "eye")
            }
        }
    }

    @ViewBuilder private var markTodaysTasksAsDoneButton: some View {
        Button(action: {
            todaysTasks.forEach { TasksData.setCompleted(for: $0, context: viewContext) }
        }) {
            Label("Mark Today as Done", systemImage: "checklist.checked")
        }
    }

    @ViewBuilder private var addUnfinishedTasksButton: some View {
        Button(action: {
            let lastUnfinishedDate = limitedPastTasks.first?.timestamp ?? Date()
            limitedPastTasks
                .filter({ $0.timestamp?.isSameDay(as: lastUnfinishedDate) ?? false })
                .filter({ !$0.completed })
                .filter({ task in !todaysTasks.contains(where: { $0.text == task.text })})
                .forEach { taskToAdd in
                    withAnimation {
                        TasksData.duplicate(taskToAdd,
                                            completed: false,
                                            order: 0,
                                            date: Date().addingTimeInterval(-1),
                                            context: viewContext)
                    }
                }

        }) {
            Label("Add Unfinished Tasks", systemImage: "arrow.uturn.up")
        }
    }
}

#Preview {
    NavigationStack {
        TaskList()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
