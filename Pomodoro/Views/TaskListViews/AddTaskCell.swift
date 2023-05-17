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
    @State var noteText = ""
    @State var completed = false
    
    var scrollProxy: ScrollViewProxy
    let id = ObjectIdentifier(Double.self)
    
    @FocusState var focus
    
    var body: some View {
        HStack (alignment: .top, spacing: 15) {
            if taskText.isEmpty {
                Plus()
            } else {
                Check()
            }
            
            VStack {
                MainTextField()
                if !taskText.isEmpty {
                    NoteTextField()
                }
            }
        }
        
        .focused($focus)
        .onChange(of: focus) { _ in
            if focus {
                basicHaptic()
            } else {
                addTask()
            }
        }
        
        .onChange(of: taskText) { taskText in
            if taskText.isEmpty {
                completed = false
            }
        }
        
        .id(id)
        .scrollToOnFocus(proxy: scrollProxy, focus: focus, id: id)
        
        .doneButton(isPresented: focus)
    }
    
    
    @ViewBuilder
    private func MainTextField() -> some View {
        TextField("", text: $taskText, axis: .vertical)
            .onSubmitWithVerticalText(with: $taskText) {
                addTask()
            }
    }
    
    @ViewBuilder
    private func NoteTextField() -> some View {
        TextField("Add Note", text: $noteText, axis: .vertical)
            .font(.footnote)
            .foregroundColor(.secondary)
    }
    
    private func addTask() {
        guard !taskText.isEmpty else { return }
        withAnimation {
            TasksData.addTask(taskText, note: noteText, completed: completed, order: completed ? Int16.max : 0, context: viewContext)
        }
        taskText = ""
        noteText = ""
    }
    
    
    @ViewBuilder
    private func Plus() -> some View {
        let width: Double = 20
        Text("+")
            .opacity(0.5)
            .frame(width: width, height: width)
            .onTapGesture {
                focus = true
            }
    }
    
    @ViewBuilder
    private func Check() -> some View {
        let width: Double = 20
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1))
                .opacity(completed ? 1.0 : 0.5)
            Circle().frame(width: width/1.5)
                .opacity(completed ? 1.0 : 0.0)
        }
        .foregroundColor(completed ? Color("AccentColor") : .primary)
        .frame(width: width)
        .onTapGesture {
            basicHaptic()
            completed.toggle()
        }
    }
}

