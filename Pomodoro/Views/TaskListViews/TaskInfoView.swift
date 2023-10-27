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
                GroupBox {
                    TextField("Task", text: $editText, axis: .vertical)
                        .lineLimit(nil)
                    Divider()
                    TextField("Note", text: $editNote, axis: .vertical)
                        .lineLimit(nil)
                }
                .padding([.horizontal, .top])

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
                .padding([.horizontal, .top])

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
            let color = Color(project.color ?? "BarRest")
            Text(project.name ?? "Error")
                .foregroundStyle(color)
                .padding(.vertical, 2).padding(.horizontal, 8)
                .brightness(colorScheme == .dark ? 0.2 : -0.5)
                .saturation(colorScheme == .dark ? 1.1 : 1.2)
                .background(
                    gradientRectangle(color: color)
                        .brightness(colorScheme == .dark ? -0.35 : 0.15)
                        .saturation(colorScheme == .dark ? 0.4 : 0.6)
                        .opacity(colorScheme == .dark ? 0.6 : 0.5)
                )
                .opacity(colorScheme == .dark ? 1.0 : 0.8)
        }
    }

    @ViewBuilder func gradientRectangle(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
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
