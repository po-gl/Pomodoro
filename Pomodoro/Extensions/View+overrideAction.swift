//
//  View+overrideAction.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/27/23.
//

import SwiftUI

extension View {
    func overrideAction(predicate: Bool, newAction: @escaping () -> Void) -> some View {
        ModifiedContent(content: self, modifier: OverrideActionViewModifier(predicate: predicate,
                                                                            action: newAction))
    }
}

struct OverrideActionViewModifier: ViewModifier {
    var predicate = false
    var action: () -> Void = {}

    func body(content: Content) -> some View {
        content
            .disabled(predicate)
            .overlay {
                if predicate {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: action)
                }
            }
    }
}
