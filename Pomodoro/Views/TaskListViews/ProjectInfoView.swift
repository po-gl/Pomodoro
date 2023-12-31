//
//  ProjectInfoView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/15/23.
//

import SwiftUI

struct ProjectInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var project: Project
    @State var editText = ""
    @State var editNote = ""
    @State var editColor = "BarRest"
    @State var editArchived = false
    @State var taskNotes = [TaskNote]()

    @State var cancelled = false

    var colorNames: [String] = ["BarRest", "BarWork", "BarLongBreak", "End", "AccentColor"]

    var collapsedBackgroundBrightness: Double { colorScheme == .dark ? -0.09 : 0.1 }
    var collapsedBackgroundSaturation: Double { colorScheme == .dark ? 0.8 : 1.1 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.7 : 0.33 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    selectedColorView
                    GroupBox {
                        TextField("Project Name", text: $editText, axis: .vertical)
                            .font(.title2)
                            .foregroundColor(Color(editColor))
                        Divider()
                        TextField("Note", text: $editNote, axis: .vertical)
                    }

                    GroupBox {
                        Grid {
                            GridRow {
                                ForEach(colorNames, id: \.self) { name in
                                    colorSelect(name: name)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityLabel("Color selection")

                    GroupBox {
                        Toggle(isOn: $editArchived) {
                            HStack(spacing: 15) {
                                Image(systemName: "archivebox.fill")
                                    .foregroundColor(Color("End"))
                                    .frame(width: 20, height: 20)
                                    .saturation(editArchived ? 1.0 : 0.0)
                                    .animation(.spring, value: editArchived)
                                Text("Archived")
                            }
                        }
                    }

                    GroupBox {
                        VStack {
                            HStack {
                                Text("Assigned Tasks (\(taskNotes.count))")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            if !taskNotes.isEmpty {
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .frame(height: 5)
                            }
                            assignedTasksList
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                editText = project.name ?? ""
                editNote = project.note ?? ""
                editColor = project.color ?? "BarRest"
            }
            .onDisappear {
                if !cancelled {
                    saveEdits()
                }
            }
            .task {
                let result = await project.tasksArray
                await MainActor.run {
                    taskNotes = result
                }
            }

            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Project Details")
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

    @ViewBuilder var assignedTasksList: some View {
        VStack(spacing: 10) {
            ForEach(taskNotes) { taskItem in
                TaskCell(taskItem: taskItem,
                         isEmbedded: true)
                Divider()
            }
        }
    }

    @ViewBuilder var selectedColorView: some View {
        let size: Double = 80
        HStack {
            gradientCircle(Color(editColor))
                .frame(width: size, height: size)
                .brightness(collapsedBackgroundBrightness)
                .saturation(collapsedBackgroundSaturation)

            gradientCircle(Color(editColor))
                .frame(width: size, height: size)
                .brightness(backgroundBrightness)
                .saturation(backgroundSaturation)
                .overlay(
                    gradientBorder(Color(editColor))
                        .brightness(collapsedBackgroundBrightness)
                        .saturation(collapsedBackgroundSaturation)
                )
        }
    }

    @ViewBuilder func colorSelect(name: String) -> some View {
        let size: Double = 40
        Button(action: { editColor = name }) {
            gradientCircle(Color(name))
                .frame(width: size, height: size)
        }
    }

    @ViewBuilder func gradientCircle(_ color: Color) -> some View {
        Circle()
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
    }

    @ViewBuilder func gradientBorder(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color.gradient, lineWidth: 2)
            .rotationEffect(.degrees(180))
    }

    func saveEdits() {
        ProjectsData.edit(editText,
                          note: editNote,
                          color: editColor,
                          archivedDate: editArchived ? Date.now : nil,
                          for: project, context: viewContext)
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
        ProjectInfoView(project: Project(context: context))
            .environment(\.managedObjectContext, context)
    }
}
