//
//  TaskList.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/12/23.
//

import SwiftUI
import CoreData


struct TaskList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\Project.order), SortDescriptor(\Project.timestamp)],
                  predicate: NSPredicate(format: "archived == false"))
    private var currentProjects: FetchedResults<Project>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\Project.order), SortDescriptor(\Project.timestamp)],
                  predicate: NSPredicate(format: "archived == true"))
    private var archivedProjects: FetchedResults<Project>
                  
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\TaskNote.order, order: .reverse), SortDescriptor(\TaskNote.timestamp, order: .forward)],
                  predicate: NSPredicate(format: "timestamp >= %@ && timestamp <= %@",
                                         Calendar.current.startOfDay(for: Date()) as CVarArg,
                                         Calendar.current.startOfDay(for: Date() + 86400) as CVarArg))
    private var todaysTasks: FetchedResults<TaskNote>
    
    @SectionedFetchRequest(sectionIdentifier: \TaskNote.section,
                           sortDescriptors: [SortDescriptor(\TaskNote.timestamp, order: .reverse)],
                           predicate: NSPredicate(format: "timestamp < %@", Calendar.current.startOfDay(for: Date()) as CVarArg))
    private var pastTasks: SectionedFetchResults<String, TaskNote>
    
    
    @AppStorage("showArchivedProjects") private var showArchivedProjects = false
    @AppStorage("showPastTasks") private var showPastTasks = false
    
    
    var body: some View {
        ZStack {
            ScrollViewReader { scrollProxy in
                List {
                    ProjectSection(scrollProxy: scrollProxy)
                    TaskSection(scrollProxy: scrollProxy)
                }
                .background(Color("BackgroundStopped").ignoresSafeArea())
                .scrollContentBackground(.hidden)
                .toolbarBackground(Color("BackgroundStopped").opacity(0.6), for: .navigationBar)
                
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle(dayFormatter.string(from: Date()))
        .navigationBarTitleDisplayMode(.large)
        
        .toolbar {
            Menu {
                ShowArchivedProjectsButton()
                Divider()
                ShowPastTasksButton()
                MarkTodaysTasksAsDoneButton()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        
        .onAppear {
            sortTasks()
        }
        
        .onChange(of: scenePhase) { scenePhase in
            // Dismiss to avoid awkard animation due to
            // hosting view controller reattaching 
            if scenePhase == .background { dismiss() }
        }
    }
    
    @ViewBuilder
    private func ProjectSection(scrollProxy: ScrollViewProxy) -> some View {
        CurrentProjects(scrollProxy: scrollProxy)
        
        if showArchivedProjects {
            ArchivedProjects(scrollProxy: scrollProxy)
        }
    }
    
    @ViewBuilder
    private func TaskSection(scrollProxy: ScrollViewProxy) -> some View {
        TodaysTasks(scrollProxy: scrollProxy)
        
        if showPastTasks {
            PastTasks(scrollProxy: scrollProxy)
        }
    }
    
    
    // MARK: Projects section views
    
    @ViewBuilder
    private func CurrentProjects(scrollProxy: ScrollViewProxy) -> some View {
        Section("Projects") {
            ForEach(currentProjects) { project in
                ProjectCellWithModifiers(project, scrollProxy: scrollProxy)
            }
            .onMove(perform: moveProjects)
            
            AddProjectCell(scrollProxy: scrollProxy)
                .moveDisabled(true)
        }
        .listRowBackground(Color("BackgroundStopped")
            .brightness(colorScheme == .dark ? 0.13 : -0.04)
            .saturation(colorScheme == .dark ? 0.0 : 1.3))
    }
    
    @ViewBuilder
    private func ArchivedProjects(scrollProxy: ScrollViewProxy) -> some View {
        Section("Archived Projects") {
            ForEach(archivedProjects) { project in
                ProjectCellWithModifiers(project, scrollProxy: scrollProxy)
                    .opacity(0.5)
            }
        }
        .listRowBackground(Color("BackgroundStopped")
            .brightness(colorScheme == .dark ? 0.13 : -0.04)
            .saturation(colorScheme == .dark ? 0.0 : 1.3))
    }
    
    @ViewBuilder
    private func ProjectCellWithModifiers(_ project: Project, scrollProxy: ScrollViewProxy) -> some View {
        ZStack (alignment: .leading) {
            // glitches occur on delete without a reference to .order in view
            Text("\(project.order)").opacity(0)
            
            ProjectItemCell(project: project, scrollProxy: scrollProxy)
                .padding(.vertical, 6)
                .id(project.id)
            
                .swipeActions(edge: .trailing) {
                    ToggleProjectArchiveButton(project)
                    DeleteProjectButton(project)
                }
        }
    }
    
    @ViewBuilder
    private func ToggleProjectArchiveButton(_ project: Project) -> some View {
        Button(action: {
            withAnimation { ProjectsData.toggleArchive(project, context: viewContext) }
        }) {
            Label(project.archived ? "Unarchive" : "Archive", systemImage: "archivebox.fill")
        }.tint(project.archived ? Color("BarWork") : Color("End"))
    }
    
    @ViewBuilder
    private func DeleteProjectButton(_ project: Project) -> some View {
        Button(role: .destructive, action: {
            withAnimation { ProjectsData.delete(project, context: viewContext) }
        }) {
            Label("Delete", systemImage: "trash")
        }.tint(.red)
    }
    
    
    // MARK: Tasks section views
    
    @ViewBuilder
    private func TodaysTasks(scrollProxy: ScrollViewProxy) -> some View {
        Section("Tasks") {
            ForEach(todaysTasks) { taskItem in
                TaskCellWithModifiers(taskItem, scrollProxy: scrollProxy)
            }
            .onMove(perform: moveTasks)
            
            AddTaskCell(scrollProxy: scrollProxy)
                .moveDisabled(true)
        }
        .listRowBackground(Color("BackgroundStopped"))
    }
    
    @ViewBuilder
    private func PastTasks(scrollProxy: ScrollViewProxy) -> some View {
        ForEach(pastTasks) { section in
            Section(section.id) {
                ForEach(section) { taskItem in
                    TaskCellWithModifiers(taskItem, scrollProxy: scrollProxy)
                        .opacity(0.5)
                }
            }
            .listRowBackground(Color("BackgroundStopped"))
        }
    }
    
    @ViewBuilder
    private func TaskCellWithModifiers(_ taskItem: TaskNote, scrollProxy: ScrollViewProxy) -> some View {
        ZStack (alignment: .leading) {
            // glitches occur on delete without a reference to .order in view
            Text("\(taskItem.order)").opacity(0)
            
            TaskItemCell(taskItem: taskItem, scrollProxy: scrollProxy)
                .padding(.vertical, 3)
                .id(taskItem.id)
            
                .swipeActions(edge: .trailing) {
                    if taskItem.timestamp! < Calendar.current.startOfDay(for: Date()) {
                        ReAddToTodaysTasksButton(taskItem)
                    }
                    DeleteTaskButton(taskItem)
                }
            
                .onChange(of: taskItem.completed) { completed in
                    Task {
                        try? await Task.sleep(for: .seconds(1.0))
                        undoManager?.disableUndoRegistration()
                        sortTasks()
                        undoManager?.enableUndoRegistration()
                    }
                }
        }
    }
    
    @ViewBuilder
    private func ReAddToTodaysTasksButton(_ taskItem: TaskNote) -> some View {
        Button(action: {
            if let taskText = taskItem.text {
                guard !TasksData.todaysTasksContains(taskText, context: viewContext) else { return }
                withAnimation { TasksData.addTask(taskText, note: taskItem.note ?? "", context: viewContext) }
            }
        }) {
            Label("Add to Today", systemImage: "arrow.uturn.up")
        }.tint(.blue)
    }
    
    @ViewBuilder
    private func DeleteTaskButton(_ taskItem: TaskNote) -> some View {
        Button(role: .destructive, action: {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        }) {
            Label("Delete", systemImage: "trash")
        }.tint(.red)
    }
    
    
    private func sortTasks() {
        withAnimation {
            TasksData.separateCompleted(todaysTasks, context: viewContext)
        }
    }
    
    private func moveProjects(from source: IndexSet, to destination: Int) {
        var revisedItems: [Project] = currentProjects.map{ $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)

        for reverseIndex in stride(from: revisedItems.count-1, through: 0, by: -1) {
            revisedItems[reverseIndex].order =
                Int16(reverseIndex)
        }
    }
    
    private func moveTasks(from source: IndexSet, to destination: Int) {
        var revisedItems: [TaskNote] = todaysTasks.map{ $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination )

        for reverseIndex in 0..<revisedItems.count {
            revisedItems[revisedItems.count-1-reverseIndex].order =
                Int16(reverseIndex)
        }
        TasksData.saveContext(viewContext)
        
        sortTasks()
    }
    
    
    @ViewBuilder
    private func ShowArchivedProjectsButton() -> some View {
        Button(action: {
            basicHaptic()
            withAnimation { showArchivedProjects.toggle() }
        }) {
            if showArchivedProjects {
                Label("Hide Archived Projects", systemImage: "eye.slash.fill")
            } else {
                Label("Show Archived Projects", systemImage: "eye.fill")
            }
        }
    }
    
    @ViewBuilder
    private func ShowPastTasksButton() -> some View {
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
    private func MarkTodaysTasksAsDoneButton() -> some View {
        Button(action: {
            todaysTasks.forEach { TasksData.setCompleted(for: $0, context: viewContext) }
        }) {
            Label("Mark Today as Done", systemImage: "checklist.checked")
        }
    }
}

fileprivate let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("EEEE MMM d")
    return formatter
}()

struct TaskList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskList().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
