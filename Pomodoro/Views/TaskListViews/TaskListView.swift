//
//  TaskListView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/23.
//

import SwiftUI

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State var showingArchivedProjects = false
    @AppStorage("showPastTasks") var showPastTasks = true

    @FetchRequest(fetchRequest: TasksData.todaysTasksRequest)
    var todaysTasks: FetchedResults<TaskNote>

    @FetchRequest(fetchRequest: TasksData.yesterdaysTasksRequest)
    var yesterdaysTasks: FetchedResults<TaskNote>

    var body: some View {
        TaskListCollectionView(showPastTasks: $showPastTasks)
            .ignoresSafeArea(.keyboard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Add task") {
                        TasksData.addTask("New task", context: viewContext)
                    }
                }
            }
            .toolbar {
                Menu {
                    showArchivedProjectsButton()
                    Divider()
                    showPastTasksButton()
                    markTodaysTasksAsDoneButton()
                    addYesterdaysUnfinishedTasksButton()
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .navigationDestination(isPresented: $showingArchivedProjects) {
                    ArchivedProjectsView()
                }
            }
    }

    @ViewBuilder
    private func showArchivedProjectsButton() -> some View {
        Button(action: {
            basicHaptic()
            showingArchivedProjects = true
        }) {
            Label("Show Archived Projects", systemImage: "eye.fill")
        }
    }

    @ViewBuilder
    private func showPastTasksButton() -> some View {
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

    @ViewBuilder
    private func markTodaysTasksAsDoneButton() -> some View {
        Button(action: {
            todaysTasks.forEach { TasksData.setCompleted(for: $0, context: viewContext) }
        }) {
            Label("Mark Today as Done", systemImage: "checklist.checked")
        }
    }

    @ViewBuilder
    private func addYesterdaysUnfinishedTasksButton() -> some View {
        Button(action: {
            yesterdaysTasks
                .filter({ !$0.completed })
                .filter({ task in !todaysTasks.contains(where: { $0.text == task.text })})
                .forEach { taskToAdd in
                if let taskText = taskToAdd.text {
                    withAnimation {
                        TasksData.addTask(taskText,
                                          note: taskToAdd.note ?? "",
                                          flagged: taskToAdd.flagged,
                                          date: Date().addingTimeInterval(-1),
                                          context: viewContext)
                    }
                }
            }

        }) {
            Label("Add Unfinished Tasks", systemImage: "arrow.uturn.up")
        }
    }
}

#Preview {
    NavigationStack {
        TaskListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
