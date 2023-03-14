//
//  TaskItemCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI

struct TaskItemCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskItem: TaskNote
    
    @State var editText = ""
    @FocusState var focus
    
    var body: some View {
        HStack (alignment: .top, spacing: 15) {
            Check().padding(.top, 3)
            TextField("", text: $editText, axis: .vertical)
                .focused($focus)
                .onSubmitWithVerticalText(with: $editText) {
                    TasksData.editText(editText, for: taskItem, context: viewContext)
                }
                .submitLabel(.done)
                .onChange(of: focus) { _ in
                    guard !focus else { return }
                    TasksData.editText(editText, for: taskItem, context: viewContext)
                }
        }
        .padding(.vertical, 5)
        .onAppear {
            editText = taskItem.text!
        }
    }
    
    @ViewBuilder
    private func Check() -> some View {
        let width: Double = 16
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1))
                .opacity(taskItem.completed ? 1.0 : 0.5)
            Circle().frame(width: width/1.5)
                .opacity(taskItem.completed ? 1.0 : 0.0)
        }
        .foregroundColor(taskItem.completed ? Color("AccentColor") : .primary)
        .frame(width: width)
        .onTapGesture {
            basicHaptic()
            TasksData.toggle(for: taskItem, context: viewContext)
        }
    }
}

