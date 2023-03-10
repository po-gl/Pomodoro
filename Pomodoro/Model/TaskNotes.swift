//
//  TaskNotes.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/10/23.
//

import SwiftUI

class TaskNotes: ObservableObject {
    @Published var tasks: [String] = []
    @Published var pomoHighlight: [Bool] = []
    
    @Published var dragText: String = ""
    @Published var dragLocation: CGPoint?
    @Published var dragHasEnded: Bool = true
    
    
    func setTaskAmount(for pomoTimer: PomoTimer) {
        if pomoTimer.order.count > tasks.count {
            var newTasks = Array(repeating: "", count: pomoTimer.order.count)
            if !tasks.isEmpty {
                newTasks.replaceSubrange(0...tasks.count-1, with: tasks)
            }
            tasks = newTasks
        }
        
        pomoHighlight = Array(repeating: false, count: pomoTimer.order.count)
    }
    
    func saveToUserDefaults() {
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(tasks, forKey: "taskNotes")
    }
    
    func restoreFromUserDefaults() {
        tasks = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "taskNotes") as? [String] ?? tasks
        print("RESTORE::tasks=\(tasks)")
    }
    
}
