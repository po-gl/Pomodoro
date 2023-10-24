//
//  TaskListView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/23.
//

import SwiftUI

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TaskListCollectionView()
            .navigationTitle("New List Style")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Add task") {
                        TasksData.addTask("New task", context: viewContext)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    NavigationStack {
        TaskListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
