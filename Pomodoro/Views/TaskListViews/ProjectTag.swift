//
//  ProjectTag.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/27/23.
//

import SwiftUI

struct ProjectTag: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var project: Project

    @State var showingProjectInfo = false

    var font: Font = .callout

    var name: String = "error"
    var color: Color = Color("BarRest")

    var body: some View {
        let name = project.name ?? name
        let color = project.color != nil ? Color(project.color!) : color
        Text(name)
            .font(font)
            .foregroundStyle(color)
            .padding(.vertical, 2).padding(.horizontal, 8)
            .brightness(colorScheme == .dark ? 0.2 : -0.5)
            .saturation(colorScheme == .dark ? 1.1 : 1.2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .rotationEffect(.degrees(180))
                    .brightness(colorScheme == .dark ? -0.35 : 0.15)
                    .saturation(colorScheme == .dark ? 0.4 : 0.6)
                    .opacity(colorScheme == .dark ? 0.6 : 0.5)
            )
            .opacity(colorScheme == .dark ? 1.0 : 0.8)

            .sheet(isPresented: $showingProjectInfo) {
                ProjectInfoView(project: project)
            }
            .onTapGesture {
                withAnimation { showingProjectInfo = true }
            }
    }
}

#Preview {
    VStack {
        let context = PersistenceController.preview.container.viewContext
        let project = Project(context: context)
        ProjectTag(project: project, name: "Apps", color: Color("BarRest"))
        ProjectTag(project: project, name: "Work", color: Color("BarWork"))
        ProjectTag(project: project, name: "Dev Environment", color: Color("BarLongBreak"))
        ProjectTag(project: project, name: "Issues", color: Color("End"))
        ProjectTag(project: project, name: "Embedded Project", color: Color("AccentColor"))
    }
}
