//
//  AddProjectCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct AddProjectCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var projectName = ""
    
    var scrollProxy: ScrollViewProxy
    let id = ObjectIdentifier(Int.self)
    
    @FocusState var focus
    
    var body: some View {
        TextField("+", text: $projectName, axis: .vertical)
            .font(.title3)
            .focused($focus)
            .onSubmitWithVerticalText(with: $projectName) {
                addProject()
            }
            .onChange(of: focus) { _ in
                guard !focus else { return }
                addProject()
            }
            .id(id)
            .scrollToOnFocus(proxy: scrollProxy, focus: focus, id: id)
    }
    
    private func addProject() {
        guard !projectName.isEmpty else { return }
        withAnimation {
            ProjectsData.addProject(projectName, context: viewContext)
        }
        projectName = ""
    }
}

