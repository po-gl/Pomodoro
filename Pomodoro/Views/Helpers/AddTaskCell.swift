//
//  AddTaskCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI

struct AddTaskCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var taskText = ""
    
    @FocusState var focus
    
    var body: some View {
        TextField("+", text: $taskText, axis: .vertical)
            .focused($focus)
            .onSubmitWithVerticalText(with: $taskText) {
                addTask()
            }
            .submitLabel(.done)
            .onChange(of: focus) { _ in
                guard !focus else { return }
                addTask()
            }
    }
    
    private func addTask() {
        guard !taskText.isEmpty else { return }
        withAnimation {
            TasksData.addTask(taskText, context: viewContext)
        }
        taskText = ""
    }
}

