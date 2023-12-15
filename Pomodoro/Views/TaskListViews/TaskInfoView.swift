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

    @State var editingAssignedProjects = false

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
                        }.tint(Color("AccentColor"))
                    }

                    GroupBox {
                        VStack(alignment: .leading) {
                            HStack(spacing: 15) {
                                Text("Assigned Projects")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(action: { editingAssignedProjects.toggle() }) {
                                    Text(editingAssignedProjects ? "Done" : "Edit")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .tint(editingAssignedProjects ? Color("End") : Color("AccentColor"))
                                }
                                .padding(.trailing, 10)
                            }
                            projectsList
                                .offset(x: -5)
                        }
                    }
                    .animation(.spring(duration: 0.3), value: editingAssignedProjects)
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

    @ViewBuilder var projectsList: some View {
        WrappingHStack(models: editProjects.sorted { $0.name ?? "" < $1.name ?? ""}) { project in
            ProjectTag(project: project)
                .overrideAction(predicate: editingAssignedProjects) {
                    withAnimation(.bouncy) {
                        toggleEditProject(project)
                    }
                }
                .overlay {
                    if editingAssignedProjects {
                        TagEditingBorder(colorOnTop: false, color: Color(project.color ?? ""))
                    }
                }
        }
        VStack {
            Divider()
                .padding(.vertical, 5)
            let combinedProjects = currentProjects + initialArchivedProjects
            WrappingHStack(models: combinedProjects.filter { !editProjects.contains($0) }
                                                   .sorted { $0.name ?? "" < $1.name ?? ""}) { project in
                ProjectTag(project: project)
                    .overrideAction(predicate: editingAssignedProjects) {
                        withAnimation(.bouncy) {
                            toggleEditProject(project)
                        }
                    }
                    .saturation(0.25)
                    .overlay {
                        TagEditingBorder(colorOnTop: true, color: Color(project.color ?? ""))
                            .saturation(0.5)
                    }
            }
        }
        .frame(maxHeight: editingAssignedProjects ? .infinity : 0)
        .opacity(editingAssignedProjects ? 1 : 0)
    }

    func toggleEditProject(_ project: Project) {
        if editProjects.contains(project) {
            editProjects.remove(project)
        } else {
            editProjects.insert(project)
        }
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

struct TagEditingBorder: View {
    let colorOnTop: Bool
    let color: Color
    @State var animate = false

    var body: some View {
        let (startPoint, endPoint): (UnitPoint, UnitPoint) = colorOnTop ? (.top, .bottom) : (.bottom, .top)
        RoundedRectangle(cornerRadius: 6)
            .stroke(LinearGradient(colors: [color, .clear],
                                   startPoint: startPoint, endPoint: endPoint),
                    style: StrokeStyle(lineWidth: 1.5))
            .opacity(animate ? 1.0 : 0.2)
            .animation(.easeInOut(duration: 1.1).repeatForever(), value: animate)
            .onAppear {
                animate = true
            }
    }
}

#Preview {
    Group {
        let context = PersistenceController.preview.container.viewContext
        TaskInfoView(taskItem: TaskNote(context: context))
            .environment(\.managedObjectContext, context)
    }
}
