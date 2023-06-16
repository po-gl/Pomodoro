//
//  ProjectItemCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct ProjectItemCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var project: Project
    
    @Binding var isCollapsed: Bool
    
    var scrollProxy: ScrollViewProxy
    
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
    
    var collapsedBackgroundBrightness: Double { colorScheme == .dark ? -0.09 : 0.1 }
    var collapsedBackgroundSaturation: Double { colorScheme == .dark ? 0.8 : 1.1 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.7 : 0.33 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }
    
 

    var body: some View {
        Card {
            HStack {
                VStack (spacing: 0) {
                    HStack {
                        ProgressCheck()
                            .offset(y: isCollapsed && !editNoteText.isEmpty ? 10 : 0)
                        MainTextField()
                        if !isCollapsed {
                            InfoMenuButton().offset(y: -1)
                        }
                    }
                    if focus || !editNoteText.isEmpty {
                        NoteTextField()
                            .padding(.leading, 32)
                    }
                }
                
                Spacer()
                if isCollapsed && isFirstProject {
                    Chevron()
                } else {
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
        .scrollToOnFocus(proxy: scrollProxy, focus: focus, id: project.id)

        .doneButton(isPresented: focus)

        .onChange(of: isCollapsed) { isCollapsed in
            if isCollapsed {
                focus = false
            }
        }
        .onTapGesture {
            if isCollapsed {
                isCollapsed = false
            }
        }
    }
    
    private func focusIfJustAdded() {
        if let date = project.timestamp {
            if Date.now.timeIntervalSince(date) < 0.5 {
                withAnimation {
                    isCollapsed = false
                }
                focus = true
            }
        }
    }
    
    @ViewBuilder
    private func MainTextField() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .font(.system(size: 22))
            .frame(minHeight: 30)
            .lineLimit(isCollapsed ? 1 : Int.max, reservesSpace: false)
            .disabled(isCollapsed)
            .onSubmitWithVerticalText(with: $editText) {
                deleteOrEditProject()
            }
            .foregroundColor(color)
            .brightness(primaryBrightness)
            .saturation(primarySaturation)
    }
    
    @ViewBuilder
    private func NoteTextField() -> some View {
        TextField("Add Note", text: $editNoteText, axis: .vertical)
            .font(.system(size: 14))
            .frame(minHeight: 20)
            .lineLimit(isCollapsed ? 1 : Int.max, reservesSpace: false)
            .fixedSize(horizontal: false, vertical: !isCollapsed)
            .disabled(isCollapsed)
            .foregroundColor(color)
            .brightness(secondaryBrightness)
    }
    
    private func deleteOrEditProject() {
        if editText.isEmpty {
            ProjectsData.delete(project, context: viewContext)
        } else {
            ProjectsData.editName(editText, for: project, context: viewContext)
            ProjectsData.editNote(editNoteText, for: project, context: viewContext)
        }
    }
    
    
    @ViewBuilder
    private func Chevron() -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 25, weight: .medium))
            .foregroundColor(color)
            .brightness(primaryBrightness)
            .saturation(primarySaturation)
    }
    
    @ViewBuilder
    private func InfoMenuButton() -> some View {
        Menu {
            ShowInfoButton()
            SendToTopButton()
            ToggleProjectArchiveButton()
            DeleteProjectButton()
        } label: {
            Image(systemName: "ellipsis.circle")
                .tint(color)
        }
        .sheet(isPresented: $showingProjectInfo) {
            ProjectInfoView(project: project)
        }
    }
    
    @ViewBuilder
    private func ShowInfoButton() -> some View {
        Button(action: {
            withAnimation { showingProjectInfo = true }
        }) {
            Label("Show Project Info", systemImage: "info.circle")
        }
    }
    
    
    @ViewBuilder
    private func SendToTopButton() -> some View {
        Button(action: {
            withAnimation { ProjectsData.setAsTopProject(project, context: viewContext) }
        }) {
            Label("Send to Top", systemImage: "square.3.layers.3d.top.filled")
        }
    }
    
    @ViewBuilder
    private func ToggleProjectArchiveButton() -> some View {
        Button(action: {
            ProjectsData.toggleArchive(project, context: viewContext)
        }) {
            Label(project.archived ? "Unarchive" : "Archive", systemImage: project.archived ? "arrow.uturn.up" : "archivebox.fill")
        }
    }
    
    @ViewBuilder
    private func DeleteProjectButton() -> some View {
        Button(role: .destructive, action: {
            ProjectsData.delete(project, context: viewContext)
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func ProgressCheck() -> some View {
        let width: Double = 22
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1.2))
                .opacity(project.progress == 1.0 ? 1.0 : 0.5)
            ZStack {
                Circle()
                    .opacity(project.progress > 0.0 ? 1.0 : 0.0)
                    .mask {
                        VStack (spacing: 0) {
                            Rectangle().fill(.clear).frame(height: width * (1-project.progress))
                            Rectangle().frame(height: width * project.progress)
                        }
                    }
            }.frame(width: width/1.5)
        }
        .foregroundColor(color)
        .hueRotation(.degrees(170))
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
    private func Card(@ViewBuilder content: @escaping () -> some View) -> some View {
        HStack (alignment: .top) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: cellHeight)
        .background(
            ZStack {
                GradientRectangle()
                    .brightness(collapsedBackgroundBrightness)
                    .saturation(collapsedBackgroundSaturation)
                    .opacity(isCollapsed ? 1.0 : 0.0)
                
                GradientRectangle()
                    .brightness(backgroundBrightness)
                    .saturation(backgroundSaturation)
                    .overlay(
                        GradientBorder()
                            .brightness(collapsedBackgroundBrightness)
                            .saturation(collapsedBackgroundSaturation)
                    )
                    .opacity(isCollapsed ? 0.0 : 1.0)
            }
        )
    }
    
    @ViewBuilder
    private func GradientRectangle() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
    }
    
    @ViewBuilder
    private func GradientBorder() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(color.gradient, lineWidth: 2)
            .rotationEffect(.degrees(180))
    }
}
