//
//  View+toasts.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/21/24.
//

import SwiftUI
import Combine

struct Toast: Identifiable {
    var message: String
    var action: ToastAction = .none
    var id = UUID()
}

enum ToastAction {
    case none
    case undone
    case error
    case reAdded
    case addedToBar
    case removedFromBar
    case addedToList
    case assignedProject
    case unassignedProject
    case markedTodayAsDone
    case addedUnfinishedTasks
    case clearedPastTasks
    case projectLimit
}

extension View {
    func toasts(bottomPadding: CGFloat = .zero) -> some View {
        ModifiedContent(content: self, modifier: ToastsModifier(bottomPadding: bottomPadding))
    }
}

struct ToastsModifier: ViewModifier {
    var bottomPadding = CGFloat.zero

    @State var queue: [Toast] = []

    func body(content: Content) -> some View {
        content
            .onReceive(Publishers.toast) { toast in
                guard queue.count < 10 else { return }
                withAnimation(.bouncy) {
                    queue.insert(toast, at: 0)
                }
                Task { @MainActor in
                    let seconds = seconds(for: toast.action)
                    try? await Task.sleep(for: .seconds(seconds))
                    withAnimation(.bouncy) {
                        _ = queue.popLast()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                VStack {
                    ForEach(queue) { toast in
                        ToastView(toast: toast)
                            .transition(BlurReplaceTransition(configuration: .downUp))
                    }
                }
                .padding(.bottom, 10 + bottomPadding)
            }
    }

    func seconds(for action: ToastAction) -> Double {
        switch action {
        case .markedTodayAsDone:
            6.0
        case .addedUnfinishedTasks:
            6.0
        case .clearedPastTasks:
            8.0
        case .projectLimit:
            5.0
        default:
            2.5
        }
    }
}

struct ToastView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var viewContext

    var toast: Toast

    @State var hasBeenTapped = false

    var body: some View {
        Group {
            switch toast.action {
            case .none:
                Text(toast.message)
            case .undone:
                Text("Undone")
            case .error:
                Text("An Error Occurred")
            case .reAdded:
                HStack {
                    Text("Re-added task")
                    Image(systemName: "arrow.uturn.up")
                        .foregroundStyle(.secondary)
                }
            case .addedToBar:
                HStack {
                    Image(systemName: "arrow.turn.up.left")
                        .foregroundStyle(.secondary)
                    Text("Added to bar")
                }
            case .removedFromBar:
                HStack {
                    Image(systemName: "x.circle")
                        .foregroundStyle(.secondary)
                    Text("Removed from bar")
                }
            case .addedToList:
                HStack {
                    Text("Added to task list")
                    Image(systemName: "arrow.turn.up.right")
                        .foregroundStyle(.secondary)
                }
            case .assignedProject:
                VStack(alignment: .leading) {
                    Text("Assigned to")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(toast.message)
                            .lineLimit(1)
                        Image(systemName: "square.3.layers.3d.top.filled")
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        guard !hasBeenTapped else { return }
                        hasBeenTapped = true
                        viewContext.undoManager?.undo()
                        NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .undone))
                    }
                }
            case .unassignedProject:
                VStack(alignment: .leading) {
                    Text("Removed from")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(toast.message)
                            .lineLimit(1)
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        guard !hasBeenTapped else { return }
                        hasBeenTapped = true
                        viewContext.undoManager?.undo()
                        NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .undone))
                    }
                }
            case .markedTodayAsDone:
                VStack(alignment: .leading) {
                    Text("Tap to undo")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        if let taskCount = Int(toast.message) {
                            Text("Marked \(taskCount) task\(taskCount > 1 || taskCount == 0 ? "s" : "") as done")
                        } else {
                            Text("Marked task(s) as done")
                        }
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }
                .onTapGesture {
                    guard !hasBeenTapped else { return }
                    hasBeenTapped = true
                    viewContext.undoManager?.undo()
                    NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .undone))
                }
            case .addedUnfinishedTasks:
                VStack(alignment: .leading) {
                    Text("Tap to undo")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        if let taskCount = Int(toast.message) {
                            Text("Re-added \(taskCount) task\(taskCount > 1 || taskCount == 0 ? "s" : "")")
                        } else {
                            Text("Re-added task(s)")
                        }
                        Image(systemName: "arrow.uturn.up")
                            .foregroundStyle(.secondary)
                    }
                }
                .onTapGesture {
                    guard !hasBeenTapped else { return }
                    hasBeenTapped = true
                    viewContext.undoManager?.undo()
                    NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .undone))
                }
            case .clearedPastTasks:
                VStack(alignment: .leading) {
                    Text("Tap to undo")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        if let deletedCount = Int(toast.message) {
                            Text("Cleared \(deletedCount) task\(deletedCount > 1 || deletedCount == 0 ? "s" : "")")
                        } else {
                            Text("Cleared task(s)")
                        }
                        Image(systemName: "clear")
                            .foregroundStyle(.secondary)
                    }
                }
                .onTapGesture {
                    guard !hasBeenTapped else { return }
                    hasBeenTapped = true
                    viewContext.undoManager?.undo()
                    NotificationCenter.default.post(name: .toast, object: Toast(message: "", action: .undone))
                }
            case .projectLimit:
                VStack(alignment: .leading) {
                    Text("Active project limit")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Archive projects to add more")
                }
            }
        }
        .font(.system(.callout, design: .rounded))
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background { background }
        .frame(maxWidth: 300)
    }

    @ViewBuilder var background: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .brightness(colorScheme == .dark ? -0.04 : 0.008)
    }
}
