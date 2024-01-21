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
    case reAdded
    case addedToBar
    case addedToList
    case assignedProject
    case unassignedProject
}

extension View {
    func toasts(bottomPadding: CGFloat = .zero) -> some View {
        ModifiedContent(content: self, modifier: ToastsModifier(bottomPadding: bottomPadding))
    }
}

struct ToastsModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var viewContext

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
                    try? await Task.sleep(for: .seconds(2.5))
                    withAnimation(.bouncy) {
                        _ = queue.popLast()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                VStack {
                    ForEach(queue) { toast in
                        if #available(iOS 17, *) {
                            toastView(toast)
                                .transition(BlurReplaceTransition(configuration: .downUp))
                        } else {
                            toastView(toast)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.bottom, 10 + bottomPadding)
            }
    }

    @ViewBuilder
    func toastView(_ toast: Toast) -> some View {
        Group {
            switch toast.action {
            case .none:
                Text(toast.message)
            case .reAdded:
                HStack {
                    Text("Re-added Task")
                    Image(systemName: "arrow.uturn.up")
                        .foregroundStyle(.secondary)
                }
            case .addedToBar:
                HStack {
                    Image(systemName: "arrow.turn.up.left")
                        .foregroundStyle(.secondary)
                    Text("Added to Bar")
                }
            case .addedToList:
                HStack {
                    Text("Added to Task List")
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
                        Image(systemName: "square.3.layers.3d.top.filled")
                            .foregroundStyle(.secondary)
                    }
                }
            case .unassignedProject:
                VStack(alignment: .leading) {
                    Text("Removed from")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(toast.message)
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .font(.system(.callout, design: .rounded))
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background { background }
    }

    @ViewBuilder var background: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .brightness(colorScheme == .dark ? -0.04 : 0.008)
    }
}
