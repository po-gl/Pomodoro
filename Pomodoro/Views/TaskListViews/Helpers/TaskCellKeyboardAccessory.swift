//
//  TaskCellKeyboardAccessory.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/21/24.
//

import SwiftUI
import Combine

struct TaskCellKeyboardAccessory: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme

    @Binding var showInfoForEstimations: Bool
    @Binding var showInfoForProjects: Bool

    private enum Controls {
        case none
        case estimations
        case assignToProjects
    }

    @State private var controlsToShow: Controls = .none

    @State private var taskItem: TaskNote? = nil
    @State private var taskText: String? = nil

    @State private var isOnBar = false
    @State private var isFlagged = false
    @State private var isAssignedToProjects = false

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
            controlsToShow = .none
        }

        // Update selected TaskNote
        .onReceive(Publishers.focusedOnTask) { taskNote in
            taskItem = taskNote
            taskText = taskItem?.text

            if let text = taskItem?.text, text != "" {
                isOnBar = TasksOnBar.shared.isOnBar(text)
            } else {
                isOnBar = false
            }
            isFlagged = taskItem?.flagged ?? false
            isAssignedToProjects = taskItem?.projects?.count ?? 0 > 0
        }
    }

    var addToBarButton: some View {
        Button(action: {
            guard let taskItem else { return }
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
        .accessibilityIdentifier("\(taskText ?? "")KeyboardAddToBarButton")
    }

    var flagTaskButton: some View {
        Button(action: {
            guard let taskItem else { return }
            basicHaptic()
            Task { @MainActor in
                TasksData.toggleFlagged(for: taskItem, context: viewContext)
            }
            isFlagged.toggle()
        }) {
            if isFlagged {
                Label("Unflag", systemImage: "flag.fill")
            } else {
                Label("Flag", systemImage: "flag")
            }
        }
        .tint(.barWork)
        .accessibilityIdentifier("\(taskText ?? "")KeyboardFlagButton")
    }

    var addEstimationButton: some View {
        Button(action: {
            basicHaptic()
//            controlsToShow = controlsToShow == .estimations ? .none : .estimations
            Task {
                showInfoForEstimations = true
            }
        }) {
            Label("Add Estimation", systemImage: "target")
        }
        .tint(.tomato)
        .scaleEffect(controlsToShow == .estimations ? 1.2 : 1.0)
        .accessibilityIdentifier("\(taskText ?? "")KeyboardEstimationButton")
    }

    var assignToProjectButton: some View {
        Button(action: {
            basicHaptic()
//            controlsToShow = controlsToShow == .assignToProjects ? .none : .assignToProjects
            Task {
                showInfoForProjects = true
            }
        }) {
            if isAssignedToProjects {
                Label("Assign to Project", systemImage: "square.3.layers.3d.top.filled")
            } else {
                Label("Assign to Project", systemImage: "square.3.layers.3d")
            }
        }
        .tint(.barLongBreak)
        .scaleEffect(controlsToShow == .assignToProjects ? 1.2 : 1.0)
        .accessibilityIdentifier("\(taskText ?? "")KeyboardAssignToProjectButton")
    }
}
