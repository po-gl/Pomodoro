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
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var taskItem: TaskNote

    @FetchRequest(fetchRequest: ProjectsData.currentProjectsRequest)
    var currentProjects: FetchedResults<Project>

    @State var editText = ""
    @State var editNote = ""
    @State var editflagged = false
    @State var editProjects = Set<Project>()
    @State var initialArchivedProjects = [Project]()

    @State var cancelled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    GroupBox {
                        TextField("Task", text: $editText, axis: .vertical)
                        Divider()
                        TextField("Note", text: $editNote, axis: .vertical)
                    }
                    
                    GroupBox {
                        Toggle(isOn: $editflagged) {
                            HStack(spacing: 15) {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(Color("BarWork"))
                                    .frame(width: 20, height: 20)
                                    .saturation(editflagged ? 1.0 : 0.0)
                                    .animation(.spring, value: editflagged)
                                Text("Flagged")
                            }
                        }
                    }
                    
                    GroupBox {
                        VStack(alignment: .leading) {
                            HStack(spacing: 15) {
                                Text("Assigned Projects")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Menu {
                                    currentProjectsMenuButtons
                                } label: {
                                    Image(systemName: "pencil.line")
                                        .font(.title3)
                                        .tint(Color("AccentColor"))
                                }
                                .padding(.trailing, 10)
                            }
                            projectsList
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            .onAppear {
                editText = taskItem.text ?? ""
                editNote = taskItem.note ?? ""
                editflagged = taskItem.flagged
                editProjects = taskItem.projects as? Set<Project> ?? []
                initialArchivedProjects = editProjects.filter { $0.archived }
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

    var projectsList: some View {
        WrappingHStack(models: editProjects.sorted { $0.name ?? "" < $1.name ?? ""}) { project in
            ProjectTag(project: project)
        }
    }

    @ViewBuilder var currentProjectsMenuButtons: some View {
        ForEach(currentProjects, id: \Project.id) { project in
            projectMenuButton(project)
        }
        ForEach(initialArchivedProjects, id: \Project.id) { project in
            projectMenuButton(project)
        }
    }

    @ViewBuilder func projectMenuButton(_ project: Project) -> some View {
        let icon = if editProjects.contains(project) {
            "circlebadge.fill"
        } else {
            "circlebadge"
        }
        Button(action: {
            withAnimation(.bouncy) {
                if editProjects.contains(project) {
                    editProjects.remove(project)
                } else {
                    editProjects.insert(project)
                }
            }
        }, label: {
            HStack {
                Label("\(project.name ?? "error")\(project.archived ? " (archived)" : "")", systemImage: icon)
            }
        })
    }

    func saveEdits() {
        TasksData.edit(editText,
                       note: editNote,
                       flagged: editflagged,
                       projects: editProjects,
                       for: taskItem, context: viewContext)
    }

    var doneButton: some View {
        Button(action: {
            saveEdits()
            dismiss()
        }, label: {
            Text("Done").bold()
        })
    }

    var cancelButton: some View {
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
