//
//  DraggableTask.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/14/23.
//

import SwiftUI

struct DraggableTask: Equatable {
    var text: String = ""
    var startLocation: CGPoint?
    var location: CGPoint?
    var dragHasEnded: Bool = true
    var isDragging: Bool = false
    
    static func == (lhs: DraggableTask, rhs: DraggableTask) -> Bool {
        lhs.text == rhs.text &&
        lhs.startLocation == rhs.startLocation &&
        lhs.location == rhs.location &&
        lhs.dragHasEnded == rhs.dragHasEnded &&
        lhs.isDragging == rhs.isDragging
    }
}
