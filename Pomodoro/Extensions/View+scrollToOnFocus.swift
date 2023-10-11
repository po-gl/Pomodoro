//
//  View+scrollToOnFocus.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/24/23.
//

import SwiftUI
import Combine

extension View {
    func scrollToOnFocus(proxy: ScrollViewProxy, focus: Bool, id: ObjectIdentifier) -> some View {
        ModifiedContent(content: self, modifier: ScrollToOnFocusModifier(scrollProxy: proxy,
                                                                         focus: focus,
                                                                         id: id))
    }
}

struct ScrollToOnFocusModifier: ViewModifier {
    var scrollProxy: ScrollViewProxy
    var focus: Bool
    var id: ObjectIdentifier

    @State var hasScrolled = false

    func body(content: Content) -> some View {
        content
            .onReceive(Publishers.keyboardOpened) { _ in
                guard focus else {
                    hasScrolled = false
                    return
                }
                guard !hasScrolled else { return }

                hasScrolled = true

                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    withAnimation { scrollProxy.scrollTo(id, anchor: .bottom) }
                }
            }
    }
}
