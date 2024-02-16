//
//  ProjectsHeader.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/23.
//

import SwiftUI

struct ProjectsHeader: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var isCollapsed: ObservableValue<Bool>

    var body: some View {
        HStack(spacing: 20) {
            Text("Projects")
                .textCase(.uppercase)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Group {
                projectHeaderAddButton
                projectHeaderChevronButton
            }
            .opacity(isCollapsed.value ? 0.0 : 1.0)
        }
    }

    @ViewBuilder private var projectHeaderAddButton: some View {
        Button(action: {
            basicHaptic()
            let projects = try? viewContext.fetch(ProjectsData.currentProjectsRequest)
            guard let projects else {
                NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .error))
                return
            }

            guard projects.count < ProjectsData.currentProjectLimit else {
                NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .projectLimit))
                return
            }

            withAnimation {
                _ = ProjectsData.addProject("", context: viewContext)
            }
        }) {
            Text("Add Project")
                .textCase(.uppercase)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundColor(.barRest)
                .brightness(colorScheme == .dark ? 0.4 : -0.1)
                .saturation(colorScheme == .dark ? 1.5 : 0.9)
        }
        .accessibilityIdentifier("addProjectButton")
    }

    @ViewBuilder private var projectHeaderChevronButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                isCollapsed.value = true
            }
        }) {
            Image(systemName: "chevron.compact.up")
                .font(.system(size: 26))
                .foregroundColor(.barRest)
                .brightness(colorScheme == .dark ? 0.4 : -0.1)
                .saturation(colorScheme == .dark ? 1.5 : 0.9)
                .padding(.vertical, 2).padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(.barRest)
                        .brightness(colorScheme == .dark ? -0.5 : 0.3)
                        .saturation(colorScheme == .dark ? 0.8 : 0.7)
                )
        }
        .accessibilityIdentifier("collapseProjectStackButton")
    }
}
