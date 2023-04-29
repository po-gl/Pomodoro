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
    @State var completed = false
    
    var scrollProxy: ScrollViewProxy
    let id = ObjectIdentifier(Double.self)
    
    @FocusState var focus
    
    var body: some View {
        HStack (alignment: .top, spacing: 15) {
            if taskText.isEmpty {
                Plus().padding(.top, 3)
            } else {
                Check().padding(.top, 3)
            }
            
            TextField("", text: $taskText, axis: .vertical)
                .focused($focus)
                .onSubmitWithVerticalText(with: $taskText) {
                    addTask()
                }
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
        }
    }
    
    private func addTask() {
        guard !taskText.isEmpty else { return }
        withAnimation {
            TasksData.addTask(taskText, completed: completed, order: completed ? Int16.max : 0, context: viewContext)
        }
        taskText = ""
    }
    
    
    @ViewBuilder
    private func Plus() -> some View {
        let width: Double = 16
        Text("+")
            .opacity(0.5)
            .frame(width: width, height: width)
    }
    
    @ViewBuilder
    private func Check() -> some View {
        let width: Double = 16
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

