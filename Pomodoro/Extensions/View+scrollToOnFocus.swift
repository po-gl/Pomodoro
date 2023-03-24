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
    
    func body(content: Content) -> some View {
        content
            .onReceive(Publishers.keyboardOpened) { isReadable in
                guard focus else { return }
                withAnimation { scrollProxy.scrollTo(id, anchor: .bottom) }
            }
    }
}
