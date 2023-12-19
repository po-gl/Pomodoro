//
//  View+showTabBarForOffset.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/19/23.
//

import SwiftUI

extension View {
    func showTabBar(for dragOffset: CGFloat) -> some View {
        ModifiedContent(content: self, modifier: ShowTabBarForOffsetModifier(dragOffset: dragOffset))
    }
}

struct ShowTabBarForOffsetModifier: ViewModifier {
    var dragOffset: CGFloat

    @State var showTabBar = false
    @State var cancellableTask: Task<(), Never>?

    func body(content: Content) -> some View {
        content
            .toolbarBackground(showTabBar ? .visible : .hidden, for: .tabBar)
            .onChange(of: dragOffset) { dragOffset in
                if dragOffset > 0 {
                    cancellableTask?.cancel()
                    showTabBar = true
                } else {
                    cancellableTask?.cancel()
                    cancellableTask = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.5))
                        guard !Task.isCancelled else { return }
                        showTabBar = false
                    }
                }
            }
    }
}
