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
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\Project.order), SortDescriptor(\Project.timestamp)])
    private var projects: FetchedResults<Project>
                  
    @FetchRequest(sortDescriptors: [SortDescriptor(\TaskNote.order), SortDescriptor(\TaskNote.timestamp)],
                  predicate: NSPredicate(format: "timestamp >= %@ && timestamp <= %@",
                                         Calendar.current.startOfDay(for: Date()) as CVarArg,
                                         Calendar.current.startOfDay(for: Date() + 86400) as CVarArg))
    private var todaysTasks: FetchedResults<TaskNote>
    
    
    var body: some View {
        ZStack {
            ScrollViewReader { scrollProxy in
                List {
                    ProjectSection(scrollProxy: scrollProxy)
                    
                    TaskSection(scrollProxy: scrollProxy)
                    
                    Spacer(minLength: 300)
                        .listRowBackground(Color("BackgroundStopped"))
                }
                .background(Color("BackgroundStopped").ignoresSafeArea())
                .scrollContentBackground(.hidden)
                .toolbarBackground(Color("BackgroundStopped").opacity(0.6), for: .navigationBar)
                
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            sortTasks()
        }
    }
    
    @ViewBuilder
    private func ProjectSection(scrollProxy: ScrollViewProxy) -> some View {
        Section("Projects") {
            ForEach(projects) { project in
                if !project.archived {
                    ZStack (alignment: .leading) {
                        // glitches occur on delete without a reference to .order in view
                        Text("\(project.order)").opacity(0)
                        
                        ProjectItemCell(project: project, scrollProxy: scrollProxy)
                            .padding(.vertical, 6)
                            .id(project.id)
                        
                            .swipeActions(edge: .trailing) {
                                Button(action: { ProjectsData.archive(project, context: viewContext) }) {
                                    Label("Archive", systemImage: "archivebox.fill")
                                }.tint(Color("End"))
                                Button(role: .destructive, action: { ProjectsData.delete(project, context: viewContext) }) {
                                    Label("Delete", systemImage: "trash")
                                }.tint(.red)
                            }
                    }
                }
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
    private func TaskSection(scrollProxy: ScrollViewProxy) -> some View {
        Section("Tasks") {
            ForEach(todaysTasks) { taskItem in
                ZStack (alignment: .leading) {
                    // glitches occur on delete without a reference to .order in view
                    Text("\(taskItem.order)").opacity(0)
                    
                    TaskItemCell(taskItem: taskItem, scrollProxy: scrollProxy)
                        .padding(.vertical, 3)
                        .id(taskItem.id)
                    
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive, action: {
                                withAnimation { TasksData.delete(taskItem, context: viewContext) }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }.tint(.red)
                        }
                    
                        .onChange(of: taskItem.completed) { completed in
                            Task {
                                try? await Task.sleep(for: .seconds(1.0))
                                sortTasks()
                            }
                        }
                }
            }
            .onMove(perform: moveTasks)
            
            AddTaskCell(scrollProxy: scrollProxy)
                .moveDisabled(true)
        }
        .listRowBackground(Color("BackgroundStopped"))
    }
    
    
    private func sortTasks() {
        withAnimation {
            TasksData.sortCompleted(todaysTasks, context: viewContext)
        }
    }
    
    private func moveProjects(from source: IndexSet, to destination: Int) {
        var revisedItems: [Project] = projects.map{ $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination )

        for reverseIndex in stride(from: revisedItems.count-1, through: 0, by: -1) {
            revisedItems[reverseIndex].order =
                Int16(reverseIndex)
        }
    }
    
    private func moveTasks(from source: IndexSet, to destination: Int) {
        var revisedItems: [TaskNote] = todaysTasks.map{ $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination )

        for reverseIndex in stride(from: revisedItems.count-1, through: 0, by: -1) {
            revisedItems[reverseIndex].order =
                Int16(reverseIndex)
        }
        sortTasks()
    }
}

struct TaskList_Previews: PreviewProvider {
    static var previews: some View {
        TaskList().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
