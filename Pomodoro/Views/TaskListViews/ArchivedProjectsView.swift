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

    @State var isCollapsed = false

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack {
                    ForEach(archivedProjects) { project in
                        ProjectItemCell(project: project,
                                        isCollapsed: $isCollapsed,
                                        scrollProxy: scrollProxy,
                                        cellHeight: 85)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Archived Projects")
        .navigationBarTitleDisplayMode(.large)
        .background(Color("Background"))
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
