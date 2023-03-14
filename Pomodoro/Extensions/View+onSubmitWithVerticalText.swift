//
//  View+onSubmitWithVerticalText.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI

extension View {
    func onSubmitWithVerticalText(with text: Binding<String>, _ action: @escaping () -> Void) -> some View {
        ModifiedContent(content: self, modifier: OnSubmitWithVerticalTextModifier(text: text, action: action))
    }
}

struct OnSubmitWithVerticalTextModifier: ViewModifier {
    @Binding var text: String
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) { newValue in
                guard let lastChar = newValue.last else { return }
                if lastChar == "\n" {
                    text.removeLast()
                    action()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
    }
}
