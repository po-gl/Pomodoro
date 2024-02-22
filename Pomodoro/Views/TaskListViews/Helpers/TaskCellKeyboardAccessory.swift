//
//  TaskCellKeyboardAccessory.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/21/24.
//

import SwiftUI

struct TaskCellKeyboardAccessory: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var taskItem: TaskNote

    @Binding var showInfoForEstimations: Bool
    @Binding var showInfoForProjects: Bool

    private enum Controls {
        case none
        case estimations
        case assignToProjects
    }

    @State private var isOnBar = false
    @State private var controlsToShow: Controls = .none

    var body: some View {
        HStack {
            addToBarButton
            Spacer()
            addEstimationButton
            Spacer()
            assignToProjectButton
            Spacer()
            flagTaskButton
        }
        .animation(.spring, value: controlsToShow)
        .padding(.horizontal)
        .labelStyle(.iconOnly)
        .onAppear {
            if let text = taskItem.text {
                isOnBar = TasksOnBar.shared.isOnBar(text)
            } else {
                isOnBar = false
            }
            controlsToShow = .none
        }
    }

    var addToBarButton: some View {
        Button(action: {
            basicHaptic()
            if let text = taskItem.text, TasksOnBar.shared.isOnBar(text) {
                TasksOnBar.shared.removeTaskFromList(text)
                NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .removedFromBar))
                isOnBar = false
            } else {
                TasksOnBar.shared.addTaskFromList(taskItem.text ?? "", context: viewContext)
                NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .addedToBar))
                isOnBar = true
            }
        }) {
            if isOnBar {
                Label("Remove from Bar", systemImage: "arrowshape.turn.up.left.fill")
            } else {
                Label("Add to Bar", systemImage: "arrowshape.turn.up.left")
            }
        }
        .tint(.end)
        .brightness(colorScheme == .dark ? 0.1 : -0.15)
    }

    var flagTaskButton: some View {
        Button(action: {
            basicHaptic()
            Task { @MainActor in
                TasksData.toggleFlagged(for: taskItem, context: viewContext)
            }
        }) {
            if taskItem.flagged {
                Label("Unflag", systemImage: "flag.fill")
            } else {
                Label("Flag", systemImage: "flag")
            }
        }
        .tint(.barWork)
        .accessibilityIdentifier("\(taskItem.text ?? "")KeyboardFlagButton")
    }

    var addEstimationButton: some View {
        Button(action: {
            basicHaptic()
//            controlsToShow = controlsToShow == .estimations ? .none : .estimations
            showInfoForEstimations = true
        }) {
            Label("Add Estimation", systemImage: "target")
        }
        .tint(.tomato)
        .scaleEffect(controlsToShow == .estimations ? 1.2 : 1.0)
    }

    var assignToProjectButton: some View {
        Button(action: {
            basicHaptic()
//            controlsToShow = controlsToShow == .assignToProjects ? .none : .assignToProjects
            showInfoForProjects = true
        }) {
            if taskItem.projects?.count ?? 0 > 0 {
                Label("Assign to Project", systemImage: "square.3.layers.3d.top.filled")
            } else {
                Label("Assign to Project", systemImage: "square.3.layers.3d")
            }
        }
        .tint(.barLongBreak)
        .scaleEffect(controlsToShow == .assignToProjects ? 1.2 : 1.0)
    }
}
