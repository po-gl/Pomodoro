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

    @FetchRequest(fetchRequest: TasksData.yesterdaysTasksRequest)
    var yesterdaysTasks: FetchedResults<TaskNote>

    var body: some View {
        TaskListCollectionView(showProjects: $showProjects,
                               showPastTasks: $showPastTasks)
            .ignoresSafeArea(.keyboard)
            .background(Color("Background").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        addTaskButton
                        Spacer()
                    }
                }
            }
            .toolbar {
                Menu {
                    showArchivedProjectsButton
                    Divider()
                    showProjectsButton
                    showPastTasksButton
                    markTodaysTasksAsDoneButton
                    addYesterdaysUnfinishedTasksButton
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .navigationDestination(isPresented: $showingArchivedProjects) {
                    ArchivedProjectsView()
                }
            }
    }

    @ViewBuilder private var addTaskButton: some View {
        Button(action: {
            basicHaptic()
            TasksData.addTask("", context: viewContext)
        }) {
            Text(Image(systemName: "plus.circle.fill"))
            Text("New Task")
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
        }.tint(Color("AccentColor"))
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

    @ViewBuilder private var addYesterdaysUnfinishedTasksButton: some View {
        Button(action: {
            yesterdaysTasks
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
