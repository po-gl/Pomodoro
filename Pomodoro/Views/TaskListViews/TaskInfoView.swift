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

    var scrollToIdOnAppear: String?

    @FetchRequest(fetchRequest: ProjectsData.currentProjectsRequest)
    var currentProjects: FetchedResults<Project>

    @State var editText = ""
    @State var editNote = ""
    @State var editCompleted = false
    @State var editFlagged = false
    @State var editPomosEstimate = -1
    @State var editPomosActual = -1
    @State var editProjects = Set<Project>()
    @State var initialArchivedProjects = [Project]()

    @State var editingAssignedProjects = false

    @State var cancelled = false
    @State var isDeleting = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(spacing: 15) {
                        if let timestamp = taskItem.timestamp {
                            Text(timestamp.formatted(.dateTime.weekday().month().day().year().hour()))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        GroupBox {
                            TextField("Task", text: $editText, axis: .vertical)
                                .fontWeight(.semibold)
                                .padding(.bottom, 5)
                            Divider()
                            TextField("Note", text: $editNote, axis: .vertical)
                                .padding(.top, 5)
                        }
                        .backgroundStyle(GroupBoxBackgroundStyle())
                        
                        GroupBox {
                            Toggle(isOn: $editCompleted) {
                                Text("Completed")
                            }
                            .tint(.end)
                            .accessibilityIdentifier("completedToggle")
                        }
                        .backgroundStyle(GroupBoxBackgroundStyle())

                        GroupBox {
                            Toggle(isOn: $editFlagged) {
                                HStack(spacing: 15) {
                                    Image(systemName: "leaf.fill")
                                        .foregroundStyle(.barWork)
                                        .saturation(editFlagged ? 1.0 : 0.0)
                                        .frame(width: 20, height: 20)
                                    Text("Flagged")
                                }
                            }.tint(.accent)
                        }
                        .backgroundStyle(GroupBoxBackgroundStyle())

                        GroupBox {
                            VStack(alignment: .leading, spacing: 15) {
                                pomosEstimateView
                                if editCompleted || editPomosActual > -1 {
                                    Group {
                                        Divider()
                                            .padding(.vertical, 5)
                                        pomosActualView
                                    }
                                    .transition(transition)
                                }
                            }
                        }
                        .backgroundStyle(GroupBoxBackgroundStyle())
                        .pulseOnAppear(if: scrollToIdOnAppear == "estimate")
                        .id("estimate")

                        GroupBox {
                            VStack(alignment: .leading) {
                                HStack(spacing: 15) {
                                    Text("Assigned Projects")
                                        .foregroundStyle(.secondary)
                                        .onTapGesture {
                                            basicHaptic()
                                            editingAssignedProjects.toggle()
                                        }
                                    Spacer()
                                    Button(action: {
                                        basicHaptic()
                                        editingAssignedProjects.toggle()
                                    }) {
                                        Text(editingAssignedProjects ? "Done" : "Edit")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .tint(editingAssignedProjects ? .end : .accent)
                                    }
                                    .padding(.trailing, 10)
                                    .accessibilityIdentifier("editAssignedProjectsButton")
                                }
                                projectsList
                                    .offset(x: -5)
                            }
                        }
                        .backgroundStyle(GroupBoxBackgroundStyle())
                        .animation(.spring(duration: 0.3), value: editingAssignedProjects)
                        .pulseOnAppear(if: scrollToIdOnAppear == "projects")
                        .id("projects")

                        GroupBox {
                            Button(role: .destructive, action: {
                                isDeleting = true
                            }) {
                                Text("Delete Task")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .backgroundStyle(GroupBoxBackgroundStyle())
                        .confirmationDialog("Delete Task", isPresented: $isDeleting) {
                            Button(role: .destructive, action: {
                                dismiss()
                                TasksData.delete(taskItem, context: viewContext)
                            }) {
                                Text("Delete This Task")
                            }
                        } message: {
                            Text("Are you sure you want to delete this task?")
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if let scrollToIdOnAppear {
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.1))
                            withAnimation {
                                scroll.scrollTo(scrollToIdOnAppear, anchor: .center)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)

            .onAppear {
                editText = taskItem.text ?? ""
                editNote = taskItem.note ?? ""
                editCompleted = taskItem.completed
                editFlagged = taskItem.flagged
                editPomosEstimate = Int(taskItem.pomosEstimate)
                editPomosActual = Int(taskItem.pomosActual)
                editProjects = taskItem.projects as? Set<Project> ?? []
                initialArchivedProjects = editProjects.filter { $0.archivedDate != nil }

                if scrollToIdOnAppear ?? "" == "projects" {
                    editingAssignedProjects = true
                }
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
            .background(Color.background.ignoresSafeArea())
        }
    }

    @ViewBuilder var pomosEstimateView: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("🍅")
            Text(try! AttributedString(markdown: "How many Pomodoros do you ___estimate___ you will need for this task?"))
        }
        Picker("pomosEstimate", selection: $editPomosEstimate) {
            Text("< 1").tag(0)
            ForEach(1...6, id: \.self) { i in
                Text("\(i)").tag(i)
            }
        }
        .accessibilityIdentifier("pomosEstimatePicker")
        .pickerStyle(SegmentedPickerStyle())
        if editPomosEstimate >= 0 {
            deselect(for: $editPomosEstimate)
        }
    }

    @ViewBuilder var pomosActualView: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("🍅")
                .overlay {
                    Color.end.mask { Text("🍅") }
                        .opacity(0.6)
                        .blendMode(.hardLight)
                }
            Text(try! AttributedString(markdown: "How many Pomodoros were ___actually___ needed for this task?"))
        }
        Picker("pomosActual", selection: $editPomosActual) {
            Text("< 1").tag(0)
            ForEach(1...6, id: \.self) { i in
                Text("\(i)").tag(i)
            }
        }
        .accessibilityIdentifier("pomosActualPicker")
        .pickerStyle(SegmentedPickerStyle())
        if editPomosActual >= 0 {
            deselect(for: $editPomosActual)
        }
    }

    @ViewBuilder var projectsList: some View {
        WrappingHStack(
            models: editProjects
                .sorted {
                    if $0.order == $1.order {
                        return $0.timestamp ?? Date.now < $1.timestamp ?? Date.now
                    } else {
                        return $0.order < $1.order
                    }
                }
        ) { project in
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
            WrappingHStack(
                models: combinedProjects
                    .filter { !editProjects.contains($0) }
                    .sorted {
                        if $0.order == $1.order {
                            return $0.timestamp ?? Date.now < $1.timestamp ?? Date.now
                        } else {
                            return $0.order < $1.order
                        }
                    }
            ) { project in
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

    @ViewBuilder
    func deselect(for value: Binding<Int>) -> some View {
        HStack {
            Spacer()
            Button("Deselect") {
                value.wrappedValue = -1
            }
            .tint(.barLongBreak)
            .opacity(0.8)
        }
        .transition(transition)
    }

    func saveEdits() {
        TasksData.edit(editText,
                       note: editNote,
                       completed: editCompleted,
                       flagged: editFlagged,
                       pomosEstimate: Int16(editPomosEstimate),
                       pomosActual: Int16(editPomosActual),
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
        .accessibilityIdentifier("doneButton")
    }

    var cancelButton: some View {
        Button(action: {
            cancelled = true
            dismiss()
        }, label: {
            Text("Cancel")
        })
    }

    var transition: AnyTransition {
        return AnyTransition(BlurReplaceTransition(configuration: .downUp).animation(.easeInOut))
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
