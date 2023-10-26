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
                let projectCount = currentProjects.count

                if projectCount > 0 {
                    ForEach(0..<projectCount, id: \.self) { i in
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
                        .animation(.easeInOut(duration: isCollapsed.value ? 0.2 : 0.4), value: isCollapsed.value)
                    }
                } else {
                    EmptyProjectsView(cellHeight: collapsedRowHeight)
                }
            }
            .frame(maxHeight: isCollapsed.value ? collapsedRowHeight*1.25 : .infinity, alignment: .top)
        }
        .compositingGroup()
    }
}

#Preview {
    ScrollView {
        ProjectStack(isCollapsed: ObservableBool(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
