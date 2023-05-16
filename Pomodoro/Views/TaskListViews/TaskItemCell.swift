//
//  TaskItemCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct TaskItemCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskItem: TaskNote
    
    var scrollProxy: ScrollViewProxy
    
    @State var editText = ""
    @State var editNoteText = ""
    @FocusState var focus
    
    var body: some View {
        HStack (alignment: .top, spacing: 15) {
            Check()
            VStack (spacing: 5) {
                MainTextField()
                if focus || !editNoteText.isEmpty {
                    NoteTextField()
                }
            }
        }
       
        .onAppear {
            editText = taskItem.text!
            editNoteText = taskItem.note ?? ""
        }
        
        .focused($focus)
        .onChange(of: focus) { _ in
            guard !focus else { return }
            deleteOrEditTask()
        }
        .scrollToOnFocus(proxy: scrollProxy, focus: focus, id: taskItem.id)
        
        .doneButton(isPresented: focus)
    }
    
    @ViewBuilder
    private func MainTextField() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .onSubmitWithVerticalText(with: $editText) {
                deleteOrEditTask()
            }
    }
    
    @ViewBuilder
    private func NoteTextField() -> some View {
        TextField("Add Note", text: $editNoteText)
            .font(.footnote)
            .foregroundColor(.secondary)
    }
    
    private func deleteOrEditTask() {
        if editText.isEmpty {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        } else {
            TasksData.editText(editText, for: taskItem, context: viewContext)
            TasksData.editNote(editNoteText, for: taskItem, context: viewContext)
        }
    }
    
    
    @ViewBuilder
    private func Check() -> some View {
        let width: Double = 20
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

