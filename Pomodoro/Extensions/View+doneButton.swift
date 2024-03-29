//
//  View+doneButton.swift
//  Pomodoro
//
//  Created by Porter Glines on 5/13/23.
//

import SwiftUI

extension View {
    func doneButton(isPresented: Bool) -> some View {
        ModifiedContent(content: self, modifier: DoneButtonModifier(predicate: isPresented))
    }
}

struct DoneButtonModifier: ViewModifier {
    var predicate = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                if predicate {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                            to: nil, from: nil, for: nil)
                        }
                        .accessibilityIdentifier("doneButton")
                    }
                }
            }
    }
}
