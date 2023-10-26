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

    @ObservedObject var isCollapsed: ObservableBool

    var cellHeight: Double

    var isFirstProject: Bool = false

    @State var editText = ""
    @State var editNoteText = ""
    @FocusState var focus
    @State var color: Color = Color("BarRest")

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
                        progressCheck()
                            .offset(y: isCollapsed.value && !editNoteText.isEmpty ? 10 : 0)
                        mainTextField()
                        if !isCollapsed.value {
                            infoMenuButton().offset(y: -1)
                        }
                    }
                    if focus || !editNoteText.isEmpty {
                        noteTextField()
                            .padding(.leading, 32)
                    }
                }

                Spacer()
                if isCollapsed.value && isFirstProject {
                    chevron()
                }
            }
        }
        .onAppear {
            editText = project.name ?? ""
            editNoteText = project.note ?? ""
            color = Color(project.color ?? "BarRest")
            focusIfJustAdded()
        }
        .onChange(of: showingProjectInfo) { _ in
            editText = project.name ?? ""
            color = Color(project.color ?? "BarRest")
        }

        .focused($focus)
        .onChange(of: focus) { _ in
            guard !focus else { return }
            deleteOrEditProject()
        }

        .doneButton(isPresented: focus)

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
                focus = true
            }
        }
    }

    @ViewBuilder
    private func mainTextField() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .font(.system(size: 22))
            .frame(minHeight: 30)
            .lineLimit(isCollapsed.value ? 1 : Int.max, reservesSpace: false)
            .disabled(isCollapsed.value)
            .foregroundColor(color)
            .brightness(primaryBrightness)
            .saturation(primarySaturation)
            .onSubmitWithVerticalText(with: $editText)
    }

    @ViewBuilder
    private func noteTextField() -> some View {
        TextField("Add Note", text: $editNoteText, axis: .vertical)
            .font(.system(size: 14))
            .frame(minHeight: 20)
            .lineLimit(isCollapsed.value ? 1 : Int.max, reservesSpace: false)
            .fixedSize(horizontal: false, vertical: !isCollapsed.value)
            .disabled(isCollapsed.value)
            .foregroundColor(color)
            .brightness(secondaryBrightness)
    }

    private func deleteOrEditProject() {
        if editText.isEmpty {
            ProjectsData.delete(project, context: viewContext)
        } else {
            editProject()
        }
    }

    private func editProject() {
        ProjectsData.editName(editText, note: editNoteText, for: project, context: viewContext)
    }

    @ViewBuilder
    private func chevron() -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 25, weight: .medium))
            .foregroundColor(color)
            .brightness(primaryBrightness)
            .saturation(primarySaturation)
    }

    @ViewBuilder
    private func infoMenuButton() -> some View {
        Menu {
            showInfoButton()
            sendToTopButton()
            toggleProjectArchiveButton()
            deleteProjectButton()
        } label: {
            Image(systemName: "ellipsis.circle")
                .tint(color)
        }
        .sheet(isPresented: $showingProjectInfo) {
            ProjectInfoView(project: project)
        }
    }

    @ViewBuilder
    private func showInfoButton() -> some View {
        Button(action: {
            editProject()
            withAnimation { showingProjectInfo = true }
        }) {
            Label("Show Project Info", systemImage: "info.circle")
        }
    }

    @ViewBuilder
    private func sendToTopButton() -> some View {
        Button(action: {
            withAnimation { ProjectsData.setAsTopProject(project, context: viewContext) }
        }) {
            Label("Send to Top", systemImage: "square.3.layers.3d.top.filled")
        }
    }

    @ViewBuilder
    private func toggleProjectArchiveButton() -> some View {
        Button(action: {
            ProjectsData.toggleArchive(project, context: viewContext)
        }) {
            Label(project.archived ? "Unarchive" : "Archive",
                  systemImage: project.archived ? "arrow.uturn.up" : "archivebox.fill")
        }
    }

    @ViewBuilder
    private func deleteProjectButton() -> some View {
        Button(role: .destructive, action: {
            ProjectsData.delete(project, context: viewContext)
        }) {
            Label("Delete", systemImage: "trash")
        }
    }

    @ViewBuilder
    private func progressCheck() -> some View {
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
                gradientRectangle()
                    .brightness(collapsedBackgroundBrightness)
                    .saturation(collapsedBackgroundSaturation)
                    .opacity(isCollapsed.value ? 1.0 : 0.0)

                gradientRectangle()
                    .brightness(backgroundBrightness)
                    .saturation(backgroundSaturation)
                    .opacity(backgroundOpacity)
                    .overlay(
                        gradientBorder()
                            .brightness(collapsedBackgroundBrightness)
                            .saturation(collapsedBackgroundSaturation)
                    )
                    .opacity(isCollapsed.value ? 0.0 : 1.0)
            }
        )
    }

    @ViewBuilder
    private func gradientRectangle() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
    }

    @ViewBuilder
    private func gradientBorder() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(color.gradient, lineWidth: 2)
            .rotationEffect(.degrees(180))
    }
}
