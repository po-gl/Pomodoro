//
//  TaskCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct TaskCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskItem: TaskNote

    @State var editText = ""
    @State var editNoteText = ""
    @FocusState var focus

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            check()
            VStack(spacing: 5) {
                mainTextField()
                    .frame(minHeight: 25)
                if focus || !editNoteText.isEmpty {
                    noteTextField()
                }
            }
            if taskItem.flagged {
                flag()
            }
        }

        .onAppear {
            editText = taskItem.text!
            editNoteText = taskItem.note ?? ""

            focusIfJustAdded()
        }

        .focused($focus)
        .onChange(of: focus) { _ in
            guard !focus else { return }
            deleteOrEditTask()
        }
        .doneButton(isPresented: focus)
    }

    private func focusIfJustAdded() {
        if let date = taskItem.timestamp {
            if Date.now.timeIntervalSince(date) < 0.5 {
                focus = true
            }
        }
    }

    @ViewBuilder
    private func mainTextField() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .foregroundColor(taskItem.timestamp?.isToday() ?? true ? .primary : .secondary)
            .onSubmitWithVerticalText(with: $editText) {
                deleteOrEditTask()

                if !editText.isEmpty {
                    TasksData.addTask("", context: viewContext)
                }
            }
    }

    @ViewBuilder
    private func noteTextField() -> some View {
        TextField("Add Note", text: $editNoteText, axis: .vertical)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func deleteOrEditTask() {
        if editText.isEmpty {
            withAnimation { TasksData.delete(taskItem, context: viewContext) }
        } else {
            TasksData.editText(editText, note: editNoteText, for: taskItem, context: viewContext)
        }
    }

    @ViewBuilder
    private func check() -> some View {
        let width: Double = 20
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1.2))
                .opacity(taskItem.completed ? 1.0 : 0.5)
            Circle().frame(width: width/1.5)
                .opacity(taskItem.completed ? 1.0 : 0.0)
        }
        .foregroundColor(taskItem.completed ? Color("AccentColor") : .primary)
        .frame(width: width)
        .onTapGesture {
            basicHaptic()
            TasksData.toggleCompleted(for: taskItem, context: viewContext)
        }
    }

    @ViewBuilder
    private func flag() -> some View {
        Image(systemName: "leaf.fill")
            .foregroundColor(Color("BarWork"))
            .frame(width: 20, height: 20)
    }
}
