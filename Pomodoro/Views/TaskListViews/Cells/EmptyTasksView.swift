//
//  EmptyTasksView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/25/23.
//

import SwiftUI

struct EmptyTasksView: View {
    @Environment(\.managedObjectContext) var viewContext

    var body: some View {
        Text("No New Tasks")
            .foregroundStyle(.secondary)
            .onTapGesture {
                basicHaptic()
                TasksData.addTask("", context: viewContext)
            }
    }
}

#Preview {
    EmptyTasksView()
}
