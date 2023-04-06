//
//  AddTaskCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct AddTaskCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var taskText = ""
    
    var scrollProxy: ScrollViewProxy
    let id = ObjectIdentifier(Double.self)
    
    @FocusState var focus
    
    var body: some View {
        TextField("+", text: $taskText, axis: .vertical)
            .focused($focus)
            .onSubmitWithVerticalText(with: $taskText) {
                addTask()
            }
            .onChange(of: focus) { _ in
                guard !focus else { return }
                addTask()
            }
            .id(id)
            .scrollToOnFocus(proxy: scrollProxy, focus: focus, id: id)
    }
    
    private func addTask() {
        guard !taskText.isEmpty else { return }
        withAnimation {
            TasksData.addTask(taskText, context: viewContext)
        }
        taskText = ""
    }
}

