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

    @State var isCollapsed = true

    let collapsedRowHeight: Double = 85

    var body: some View {
        HStack(alignment: .top) {
            VStack {
                ForEach(0..<currentProjects.count, id: \.self) { i in
                    let iDouble = Double(i)
                    ProjectCell(project: currentProjects[i],
                                isCollapsed: $isCollapsed,
                                cellHeight: collapsedRowHeight,
                                isFirstProject: i == 0)
                    .zIndex(-iDouble)
                    .padding(.top, i == 0 ? 4 : 0)
                    .opacity(isCollapsed ? 1 - (0.3 * iDouble) : 1.0)
                    .scaleEffect(isCollapsed ? 1 - (0.08 * iDouble) : 1.0)
                    .offset(y: isCollapsed ? -iDouble * collapsedRowHeight + (iDouble * 3) : 0.0)
                    .compositingGroup()
                }
            }
            .frame(maxHeight: isCollapsed ? collapsedRowHeight*1.25 : .infinity, alignment: .top)
            .padding(.vertical, 3)
        }
        .animation(.easeInOut, value: isCollapsed)
    }
}

#Preview {
    ScrollView {
        ProjectStack()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
