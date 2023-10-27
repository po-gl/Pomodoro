//
//  TaskInfoView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/26/23.
//

import SwiftUI

struct TaskInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var taskItem: TaskNote

    @State var editText = ""
    @State var editNote = ""

    @State var cancelled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                GroupBox {
                    TextField("Task", text: $editText, axis: .vertical)
                        .lineLimit(nil)
                    Divider()
                    TextField("Note", text: $editNote, axis: .vertical)
                        .lineLimit(nil)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            .onAppear {
                editText = taskItem.text ?? ""
                editNote = taskItem.note ?? ""
            }
            .onDisappear {
                if !cancelled {
                    saveEdits()
                }
            }

            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    doneButton
                }
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
            }
            .background(Color("Background").ignoresSafeArea())
        }
    }

    private func saveEdits() {
        TasksData.editText(editText, note: editNote, for: taskItem, context: viewContext)
    }

    private var doneButton: some View {
        Button(action: {
            saveEdits()
            dismiss()
        }, label: {
            Text("Done").bold()
        })
    }

    private var cancelButton: some View {
        Button(action: {
            cancelled = true
            dismiss()
        }, label: {
            Text("Cancel")
        })
    }
}

#Preview {
    Group {
        let context = PersistenceController.preview.container.viewContext
        TaskInfoView(taskItem: TaskNote(context: context))
            .environment(\.managedObjectContext, context)
    }
}
