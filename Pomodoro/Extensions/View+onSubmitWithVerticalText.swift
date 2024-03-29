//
//  View+onSubmitWithVerticalText.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI

extension View {
    func onSubmitWithVerticalText(with text: Binding<String>, resigns: Bool = true, _ action: @escaping () -> Void = {}) -> some View {
        ModifiedContent(content: self, modifier: OnSubmitWithVerticalTextModifier(text: text, resigns: resigns, action: action))
    }
}

struct OnSubmitWithVerticalTextModifier: ViewModifier {
    @Binding var text: String
    let resigns: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: text) {
                guard let newLineIndex = text.firstIndex(where: { $0 == "\n" }) else { return }

                text.remove(at: newLineIndex)
                action()
                if resigns {
                    Task {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }
            }
    }
}
