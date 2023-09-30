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
                  
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\TaskNote.order, order: .reverse), SortDescriptor(\TaskNote.timestamp, order: .forward)],
                  predicate: NSPredicate(format: "timestamp >= %@ && timestamp <= %@",
                                         Calendar.current.startOfDay(for: Date()) as CVarArg,
                                         Calendar.current.startOfDay(for: Date() + 86400) as CVarArg))
    private var todaysTasks: FetchedResults<TaskNote>
    
    @SectionedFetchRequest(sectionIdentifier: \TaskNote.section,
                           sortDescriptors: [SortDescriptor(\TaskNote.timestamp, order: .reverse)],
                           predicate: NSPredicate(format: "timestamp < %@", Calendar.current.startOfDay(for: Date()) as CVarArg))
    private var pastTasks: SectionedFetchResults<String, TaskNote>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\TaskNote.order, order: .reverse), SortDescriptor(\TaskNote.timestamp, order: .forward)],
                  predicate: NSPredicate(format: "timestamp >= %@ && timestamp <= %@",
                                         Calendar.current.startOfDay(for: Date() - 86401) as CVarArg,
                                         Calendar.current.startOfDay(for: Date() - 1) as CVarArg))
    private var yesterdaysTasks: FetchedResults<TaskNote>
    
    @State var showingArchivedProjects = false
    @AppStorage("showPastTasks") private var showPastTasks = false
    
    @State private var todaysTasksID = UUID()
    
    @State var isProjectSectionCollapsed = true
    

    var body: some View {
        ZStack {
            ScrollViewReader { scrollProxy in
                List {
                    ProjectSection(scrollProxy: scrollProxy)
                    TaskSection(scrollProxy: scrollProxy)
                }
                .animation(.spring(), value: isProjectSectionCollapsed)
                .listStyle(.insetGrouped)
                .background(Color("Background").ignoresSafeArea())
                .scrollContentBackground(.hidden)
                .toolbarBackground(Color("Background").opacity(0.6), for: .navigationBar)
                .toolbarBackground(Color("Background").opacity(0.6), for: .bottomBar)
                
                .scrollDismissesKeyboard(.interactively)
                
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack {
                            AddTaskButton(scrollProxy: scrollProxy, scrollToID: todaysTasksID)
                            Spacer()
                        }
                    }
                }
            }
        }
//        .navigationTitle(dayFormatter.string(from: Date()))
        .navigationBarTitleDisplayMode(.inline)
        
        .toolbar {
            Menu {
                ShowArchivedProjectsButton()
                Divider()
                ShowPastTasksButton()
                MarkTodaysTasksAsDoneButton()
                AddYesterdaysUnfinishedTasksButton()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .navigationDestination(isPresented: $showingArchivedProjects) {
                ArchivedProjectsView()
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
        Section {
            if !currentProjects.isEmpty {
                ProjectStackList(scrollProxy: scrollProxy)
            } else {
                EmptyProjectsView()
            }
//            .onMove(perform: moveProjects)
        } header: {
            ProjectSectionHeader()
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
        
        .onChange(of: currentProjects.count) { count in
            if count == 0 {
                isProjectSectionCollapsed = true
            }
        }
    }
    
    @ViewBuilder
    private func ProjectStackList(scrollProxy: ScrollViewProxy) -> some View {
        let collapsedRowHeight: Double = 85
        HStack (alignment: .top) {
            VStack {
                ForEach(0..<currentProjects.count, id: \.self) { index in
                    ProjectCellWithModifiers(currentProjects[index], scrollProxy: scrollProxy, cellHeight: collapsedRowHeight, isFirstProject: index == 0)
                        .zIndex(-Double(index))
                        .opacity(isProjectSectionCollapsed ? 1 - (0.3 * Double(index)) : 1.0)
                        .scaleEffect(isProjectSectionCollapsed ? 1 - (0.08 * Double(index)) : 1.0)
                        .offset(y: isProjectSectionCollapsed ? -Double(index) * collapsedRowHeight + (Double(index) * 3) : 0.0)
                }
            }
            .frame(maxHeight: isProjectSectionCollapsed ? collapsedRowHeight*1.25 : .infinity, alignment: .top)
            .padding(.vertical, 3)
        }
    }
    
    @ViewBuilder
    private func ProjectSectionHeader() -> some View {
        HStack (spacing: 20) {
            Text("Projects")
            Spacer()
            Group {
                ProjectHeaderAddButton()
                ProjectHeaderChevronButton()
            }
            .opacity(isProjectSectionCollapsed ? 0.0 : 1.0)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func ProjectHeaderAddButton() -> some View {
        Button(action: {
            withAnimation(.spring()) {
                ProjectsData.addProject("", context: viewContext)
            }
        }) {
            Text("Add Project")
                .font(.footnote)
                .foregroundColor(Color("BarRest"))
                .brightness(colorScheme == .dark ? 0.4 : -0.1)
                .saturation(colorScheme == .dark ? 1.5 : 0.9)
//                .padding(.vertical, 2).padding(.horizontal, 4)
//                .background(
//                    RoundedRectangle(cornerRadius: 8).fill(Color("BarRest"))
//                        .brightness(colorScheme == .dark ? -0.5 : 0.3)
//                        .saturation(colorScheme == .dark ? 0.8 : 0.7)
//                )
        }
    }
    
    @ViewBuilder
    private func ProjectHeaderChevronButton() -> some View {
        Button(action: {
            withAnimation(.spring()) {
                isProjectSectionCollapsed = true
            }
        }) {
            Image(systemName: "chevron.compact.up")
                .font(.system(size: 26))
                .foregroundColor(Color("BarRest"))
                .brightness(colorScheme == .dark ? 0.4 : -0.1)
                .saturation(colorScheme == .dark ? 1.5 : 0.9)
                .padding(.vertical, 2).padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(Color("BarRest"))
                        .brightness(colorScheme == .dark ? -0.5 : 0.3)
                        .saturation(colorScheme == .dark ? 0.8 : 0.7)
                )
        }
    }
    
    @ViewBuilder
    private func ProjectCellWithModifiers(_ project: Project, scrollProxy: ScrollViewProxy, cellHeight: Double, isFirstProject: Bool) -> some View {
        ZStack (alignment: .leading) {
            // glitches occur on delete without a reference to .order in view
            Text("\(project.order)").opacity(0)
            
            ProjectItemCell(project: project, isCollapsed: $isProjectSectionCollapsed, scrollProxy: scrollProxy, cellHeight: cellHeight, isFirstProject: isFirstProject)
                .id(project.id)
//                .swipeActions(edge: .trailing) {
//                    ToggleProjectArchiveButton(project)
//                    DeleteProjectButton(project)
//                }
        }
    }
    

    
    // MARK: Tasks section views
    
    @ViewBuilder
    private func TaskSection(scrollProxy: ScrollViewProxy) -> some View {
        TodaysTasks(scrollProxy: scrollProxy)
        
        if showPastTasks {
            PastTasks(scrollProxy: scrollProxy)
        }
    }
    
    @ViewBuilder
    private func TodaysTasks(scrollProxy: ScrollViewProxy) -> some View {
        Section("Today's Tasks") {
            ForEach(todaysTasks) { taskItem in
                TaskCellWithModifiers(taskItem, scrollProxy: scrollProxy)
            }
            .onMove(perform: moveTasks)
            
            if todaysTasks.isEmpty {
                TodaysTasksEmptyState()
            }
        }
        .listRowBackground(Color("Background"))
        .id(todaysTasksID)
    }
    
    @ViewBuilder
    private func TodaysTasksEmptyState() -> some View {
        HStack {
            Spacer()
            Text("No New Tasks")
                .foregroundColor(.secondary)
                .onTapGesture {
                    basicHaptic()
                    TasksData.addTask("", context: viewContext)
                }
            Spacer()
        }
    }
    
    // MARK: Past Tasks section
    
    @ViewBuilder
    private func PastTasks(scrollProxy: ScrollViewProxy) -> some View {
        ForEach(pastTasks) { section in
            Section {
                ForEach(section) { taskItem in
                    TaskCellWithModifiers(taskItem, scrollProxy: scrollProxy)
                        .opacity(0.7)
                }
            } header: {
                PastSectionHeader(for: section.id)
            }
            .listRowBackground(Color("Background"))
        }
    }
    
    @ViewBuilder
    private func PastSectionHeader(for dateString: String) -> some View {
        let color = ColorForDateString(dateString)
        
        Text(dateString)
            .padding(.vertical, 2).padding(.horizontal, 8)
            .foregroundColor(color)
            .brightness(colorScheme == .dark ? 0.2 : -0.3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .brightness(colorScheme == .dark ? -0.3 : 0.15)
                    .saturation(colorScheme == .dark ? 0.3 : 0.6)
            )
            .opacity(colorScheme == .dark ? 1.0 : 0.8)
    }
    
    private func ColorForDateString(_ dateString: String) -> Color {
        let date = TaskNote.sectionFormatter.date(from: dateString)
        var progress: Double?
        let progressPerDay = 0.04
        
        if let date {
            let timeSinceDate = Date.now.timeIntervalSince(date)
            let daysSinceDate = (timeSinceDate / 60 / 60 / 24).rounded()
            progress = progressPerDay * (daysSinceDate - 1)
            progress = progress?.clamped(to: 0...1)
        }
        // NamedColor incorrectly switches from light to dark mode
        // so colors are manual here instead of Color("BarRest")
        let fromColor = colorScheme == .dark ? Color(hex: 0xD2544F) : Color(hex: 0xFC7974)
        let toColor = colorScheme == .dark ? Color(hex: 0x22B159) : Color(hex: 0x31E377)
        
        return Color.interpolate(from: fromColor, to: toColor, progress: progress ?? 1.0)
    }
    
    @ViewBuilder
    private func TaskCellWithModifiers(_ taskItem: TaskNote, scrollProxy: ScrollViewProxy) -> some View {
        ZStack (alignment: .leading) {
            // glitches occur on delete without a reference to .order in view
            Text("\(taskItem.order)").opacity(0)
            
            TaskItemCell(taskItem: taskItem, scrollProxy: scrollProxy)
                .padding(.vertical, 3)
                .id(taskItem.id)
            
                .swipeActions(edge: .leading) {
                    DeleteTaskButton(taskItem)
                }
                .swipeActions(edge: .trailing) {
                    if taskItem.timestamp! < Calendar.current.startOfDay(for: Date()) {
                        ReAddToTodaysTasksButton(taskItem)
                    }
                    FlagTaskButton(taskItem)
                }
            
                .onChange(of: taskItem.completed) { completed in
                    Task {
                        try? await Task.sleep(for: .seconds(0.3))
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
                withAnimation { TasksData.addTask(taskText, note: taskItem.note ?? "", flagged: taskItem.flagged, date: Date().addingTimeInterval(-1), context: viewContext) }
            }
        }) {
            Label("Re-add", systemImage: "arrow.uturn.up")
        }.tint(.blue)
    }
    
    @ViewBuilder
    private func FlagTaskButton(_ taskItem: TaskNote) -> some View {
        Button(action: {
            withAnimation { TasksData.toggleFlagged(for: taskItem, context: viewContext) }
        }) {
            Label(taskItem.flagged ? "Unflag" : "Flag", systemImage: taskItem.flagged ? "flag.slash.fill" : "flag.fill")
        }.tint(Color("BarWork"))
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
            showingArchivedProjects = true
        }) {
            Label("Show Archived Projects", systemImage: "eye.fill")
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
    
    @ViewBuilder
    private func AddYesterdaysUnfinishedTasksButton() -> some View {
        Button(action: {
            yesterdaysTasks.filter({ !$0.completed }).filter({ task in !todaysTasks.contains(where: { $0.text == task.text })}).forEach { taskToAdd in
                if let taskText = taskToAdd.text {
                    withAnimation { TasksData.addTask(taskText, note: taskToAdd.note ?? "", flagged: taskToAdd.flagged, date: Date().addingTimeInterval(-1), context: viewContext)}
                }
            }
                
        }) {
            Label("Add Unfinished Tasks", systemImage: "arrow.uturn.up")
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
