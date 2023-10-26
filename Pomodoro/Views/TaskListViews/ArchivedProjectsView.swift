//
//  ArchivedProjectsView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/15/23.
//

import SwiftUI

struct ArchivedProjectsView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\Project.order), SortDescriptor(\Project.timestamp)],
                  predicate: NSPredicate(format: "archived == true"))
    private var archivedProjects: FetchedResults<Project>

    @StateObject var isCollapsed = ObservableBool(false)

    var body: some View {
        ScrollView {
            VStack {
                if archivedProjects.count > 0 {
                    ForEach(archivedProjects) { project in
                        ProjectCell(project: project,
                                    isCollapsed: isCollapsed,
                                    cellHeight: 85)
                    }
                } else {
                    emptyState
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Archived Projects")
        .navigationBarTitleDisplayMode(.large)
        .background(Color("Background"))
    }

    var emptyState: some View {
        Text("No Archived Projects")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 150)
    }
}

struct ArchivedProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ArchivedProjectsView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
