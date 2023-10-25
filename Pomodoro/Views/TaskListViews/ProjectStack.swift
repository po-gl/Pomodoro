//
//  ProjectStack.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/23.
//

import SwiftUI

struct ProjectStack: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [SortDescriptor(\Project.order), SortDescriptor(\Project.timestamp)],
                  predicate: NSPredicate(format: "archived == false"))
    private var currentProjects: FetchedResults<Project>

    @ObservedObject var isCollapsed: ObservableBool

    let collapsedRowHeight: Double = 85

    var body: some View {
        HStack(alignment: .top) {
            VStack {
                ForEach(0..<currentProjects.count, id: \.self) { i in
                    let iDouble = Double(i)
                    ProjectCell(project: currentProjects[i],
                                isCollapsed: isCollapsed,
                                cellHeight: collapsedRowHeight,
                                isFirstProject: i == 0)
                    .zIndex(-iDouble)
                    .opacity(isCollapsed.value ? 1 - (0.3 * iDouble) : 1.0)
                    .scaleEffect(isCollapsed.value ? 1 - (0.08 * iDouble) : 1.0)
                    .offset(y: isCollapsed.value ? -iDouble * collapsedRowHeight + (iDouble * 3) : 0.0)
                    .compositingGroup()
                }
            }
            .frame(maxHeight: isCollapsed.value ? collapsedRowHeight*1.25 : .infinity, alignment: .top)
            .padding(.top, 10)
        }
        .animation(.easeInOut, value: isCollapsed.value)
    }
}

#Preview {
    ScrollView {
        ProjectStack(isCollapsed: ObservableBool(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
