//
//  DraggableTask.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/14/23.
//

import SwiftUI

class DraggableTask: ObservableObject {
    @Published var dragText: String = ""
    @Published var dragLocation: CGPoint?
    @Published var dragHasEnded: Bool = true
}
