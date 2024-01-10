//
//  ProjectCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/23.
//

import SwiftUI
import Combine

struct ProjectCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var project: Project

    var editText: Binding<String> {
        Binding(get: { project.name ?? "" },
                set: { newValue in project.name = newValue })
    }
    var editNoteText: Binding<String> {
        Binding(get: { project.note ?? "" },
                set: { newValue in project.note = newValue })
    }
    var color: Color {
        Color(project.color ?? "BarRest")
    }

    @State var taskNotes = [TaskNote]()

    @ObservedObject var isCollapsed: ObservableBool

    var cellHeight: Double

    var isFirstProject: Bool = false

    @FocusState var focus

    @State var showingProjectInfo = false

    var primaryBrightness: Double { colorScheme == .dark ? 0.5 : -0.5 }
    var primarySaturation: Double { colorScheme == .dark ? 1.8 : 1.2 }
    var secondaryBrightness: Double { colorScheme == .dark ? 0.2 : -0.3 }
    var secondarySaturation: Double { colorScheme == .dark ? 1.0 : 1.0 }

    var collapsedCheckBrightness: Double { colorScheme == .dark ? 0.5 : -0.5 }
    var collapsedCheckSaturation: Double { colorScheme == .dark ? 1.5 : 1.2 }
    var checkBrightness: Double { colorScheme == .dark ? 0.2 : -0.3 }
    var checkSaturation: Double { colorScheme == .dark ? 1.0 : 1.0 }

    var collapsedBackgroundBrightness: Double { colorScheme == .dark ? -0.09 : 0.0 }
    var collapsedBackgroundSaturation: Double { colorScheme == .dark ? 0.85 : 1.05 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.5 : 0.3 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }
    var backgroundOpacity: Double { colorScheme == .dark ? 0.6 : 0.5 }

    var body: some View {
        card {
            HStack {
                VStack(spacing: 0) {
                    HStack {
                        progressCheck
                            .offset(y: isCollapsed.value && !editNoteText.wrappedValue.isEmpty ? 10 : 0)
                            .padding(.trailing, 3)
                        mainTextField
                        if !isCollapsed.value {
                            infoButton.offset(y: -1)
                        }
                    }
                    Group {
                        if focus || !editNoteText.wrappedValue.isEmpty {
                            noteTextField
                        }
                        if !isCollapsed.value && taskNotes.count > 0 {
                            Divider()
                                .padding(.vertical, 6)
                            projectStats
                        }
                    }
                    .padding(.leading, 35)
                }

                Spacer()
                if isCollapsed.value && isFirstProject {
                    chevron
                }
            }
        }
        .sheet(isPresented: $showingProjectInfo) {
            ProjectInfoView(project: project)
        }

        .onAppear {
            focusIfJustAdded()
        }
        .task {
            await reloadTaskNotes()
        }
        .onChange(of: project.tasks?.count) { _ in
            Task {
                await reloadTaskNotes()
            }
        }

        .focused($focus)
        .onChange(of: focus) { _ in
            TaskListViewController.focusedIndexPath = nil
            if !focus {
                deleteOrEditProject()
            }
        }

        .doneButton(isPresented: focus)

        .customSwipeActions(leadingButtonCount: 2, trailingButtonCount: project.archivedDate == nil ? 2 : 1, leading: {
            deleteProjectButton
            slideInfoButton
        }, trailing: {
            toggleProjectArchiveButton
            if project.archivedDate == nil {
                sendToTopButton
            }
        }, disabled: isCollapsed.value)

        .onChange(of: isCollapsed.value) { isCollapsed in
            if isCollapsed {
                focus = false
            }
        }
        .onTapGesture {
            if isCollapsed.value {
                isCollapsed.value = false
            }
        }
    }

    private func focusIfJustAdded() {
        if let date = project.timestamp {
            if Date.now.timeIntervalSince(date) < 0.5 {
                withAnimation {
                    isCollapsed.value = false
                }
                editText.wrappedValue = ""
                editNoteText.wrappedValue = ""
                focus = true
            }
        }
    }

    private func reloadTaskNotes() async {
        let result = await project.tasksArray
        await MainActor.run {
            taskNotes = result
        }
    }

    @ViewBuilder private var mainTextField: some View {
        TextField("", text: editText, axis: .vertical)
            .font(.system(.title2, weight: .medium))
            .frame(minHeight: 30)
            .lineLimit(isCollapsed.value ? 1 : Int.max, reservesSpace: false)
            .disabled(isCollapsed.value)
            .foregroundColor(color)
            .brightness(primaryBrightness)
            .saturation(primarySaturation)
            .onSubmitWithVerticalText(with: editText)
    }

    @ViewBuilder private var noteTextField: some View {
        TextField("Add Note", text: editNoteText, axis: .vertical)
            .font(.system(.footnote))
            .frame(minHeight: 20)
            .lineLimit(isCollapsed.value ? 1 : Int.max, reservesSpace: false)
            .fixedSize(horizontal: false, vertical: !isCollapsed.value)
            .disabled(isCollapsed.value)
            .foregroundColor(color)
            .brightness(secondaryBrightness)
            .id("\(project.id)_note_\(isCollapsed.value)")
    }

    @ViewBuilder private var projectStats: some View {
        let assignedCount = taskNotes.count
        let completedCount = taskNotes.filter { $0.completed }.count

        let assignedString = "\(assignedCount) assigned task\(assignedCount > 1 ? "s" : "")"
        let tasksString = completedCount == 0 ? assignedString : "\(completedCount) completed / \(assignedString)"

        HStack {
            Spacer()
            Text(tasksString)
                .font(.system(.footnote))
                .foregroundColor(color)
                .brightness(secondaryBrightness)
                .onTapGesture {
                    editProject()
                    withAnimation { showingProjectInfo = true }
                }
        }
    }

    private func deleteOrEditProject() {
        if editText.wrappedValue.isEmpty {
            ProjectsData.delete(project, context: viewContext)
        } else {
            editProject()
        }
    }

    private func editProject() {
        ProjectsData.saveContext(viewContext, errorMessage: "Saving project cell")
    }

    @ViewBuilder private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 25, weight: .medium))
            .foregroundColor(color)
            .brightness(primaryBrightness)
            .saturation(primarySaturation)
    }

    @ViewBuilder private var infoButton: some View {
        Button(action: {
            editProject()
            withAnimation { showingProjectInfo = true }
        }) {
            Image(systemName: "info.circle")
                .font(.title3)
                .tint(color)
        }
    }

    @ViewBuilder private var slideInfoButton: some View {
        Button(action: {
            editProject()
            withAnimation { showingProjectInfo = true }
        }) {
            Label("Show Project Info", systemImage: "info.circle.fill")
        }.tint(Color(.lightGray))
    }

    @ViewBuilder private var sendToTopButton: some View {
        Button(action: {
            withAnimation { ProjectsData.setAsTopProject(project, context: viewContext) }
        }) {
            Label("Send to Top", systemImage: "square.3.layers.3d.top.filled")
        }.tint(Color("BarWork"))
    }

    @ViewBuilder private var toggleProjectArchiveButton: some View {
        Button(action: {
            ProjectsData.toggleArchive(project, context: viewContext)
        }) {
            Label(project.archivedDate != nil ? "Unarchive" : "Archive",
                  systemImage: project.archivedDate != nil ? "arrow.uturn.up" : "archivebox.fill")
        }.tint(Color("End"))
    }

    @ViewBuilder private var deleteProjectButton: some View {
        Button(role: .destructive, action: {
            ProjectsData.delete(project, context: viewContext)
        }) {
            Label("Delete", systemImage: "trash.fill")
        }.tint(.red)
    }

    @ViewBuilder private var progressCheck: some View {
        let width: Double = 22
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1.8))
                .opacity(project.progress == 1.0 ? 1.0 : 0.5)
            ZStack {
                Circle()
                    .opacity(project.progress > 0.0 ? 1.0 : 0.0)
                    .mask {
                        VStack(spacing: 0) {
                            Rectangle().fill(.clear).frame(height: width * (1-project.progress))
                            Rectangle().frame(height: width * project.progress)
                        }
                    }
            }.frame(width: width/1.5)
        }
        .foregroundColor(color)
        .brightness(isCollapsed.value ? collapsedCheckBrightness : checkBrightness)
        .saturation(isCollapsed.value ? collapsedCheckSaturation : checkSaturation)
        .contentShape(Circle())
        .onTapGesture {
            let newValue = project.progress + 0.5 > 1.0 ? 0.0 : project.progress + 0.5

            withAnimation {
                ProjectsData.setProgress(newValue, for: project, context: viewContext)
            }

            if newValue == 1.0 {
                resetHaptic()
            } else {
                basicHaptic()
            }
        }
        .frame(width: width, height: width)
    }

    @ViewBuilder
    private func card(@ViewBuilder content: @escaping () -> some View) -> some View {
        HStack(alignment: .top) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: cellHeight)
        .background(
            ZStack {
                gradientRectangle
                    .brightness(collapsedBackgroundBrightness)
                    .saturation(collapsedBackgroundSaturation)
                    .opacity(isCollapsed.value ? 1.0 : 0.0)

                gradientRectangle
                    .brightness(backgroundBrightness)
                    .saturation(backgroundSaturation)
                    .opacity(backgroundOpacity)
                    .overlay(
                        gradientBorder
                            .brightness(collapsedBackgroundBrightness)
                            .saturation(collapsedBackgroundSaturation)
                    )
                    .opacity(isCollapsed.value ? 0.0 : 1.0)
            }
        )
    }

    @ViewBuilder private var gradientRectangle: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
    }

    @ViewBuilder private var gradientBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(color.gradient, lineWidth: 2)
            .rotationEffect(.degrees(180))
    }
}
