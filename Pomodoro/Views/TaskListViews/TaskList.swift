//
//  TaskList.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/23.
//

import SwiftUI

struct TaskList: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State var showingArchivedProjects = false
    @AppStorage("showProjects") var showProjects = true
    @AppStorage("showPastTasks") var showPastTasks = true

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    @FetchRequest(fetchRequest: TasksData.limitedPastTasksRequest)
    var limitedPastTasks: FetchedResults<TaskNote>

    @StateObject var isScrolledToTop = ObservableBool(true)

    var body: some View {
        NavigationStack {
            TaskListCollectionView(showProjects: showProjects,
                                   showPastTasks: showPastTasks,
                                   isScrolledToTop: isScrolledToTop)
            .ignoresSafeArea(.keyboard)
            .background(Color("Background").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Task List")
            .toolbar {
                Menu {
                    showArchivedProjectsButton
                    Divider()
                    showProjectsButton
                    showPastTasksButton
                    markTodaysTasksAsDoneButton
                    addUnfinishedTasksButton
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .navigationDestination(isPresented: $showingArchivedProjects) {
                    ArchivedProjectsView()
                }
            }
            .ignoresSafeArea(edges: .vertical)
            .safeAreaInset(edge: .top) {
                Color.clear
                    .frame(height: 0)
                    .background(.bar)
                    .border(.thinMaterial)
                    .opacity(isScrolledToTop.value ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isScrolledToTop.value)
            }
        }
        .navigationViewStyle(.stack)
        .tint(Color("NavigationAccent"))
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
