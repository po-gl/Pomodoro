//
//  TaskNotes.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/10/23.
//

import SwiftUI
import CoreData

class TasksOnBar: ObservableObject {
    @Published var tasksOnBar: [String] = []
    @Published var pomoHighlight: [Bool] = []
    @Published var draggableTasksOnBar: [DraggableTask] = []

    func setTaskAmount(for pomoTimer: PomoTimer) {
        if pomoTimer.order.count > tasksOnBar.count {
            var newTasks = Array(repeating: "", count: pomoTimer.order.count)
            if !tasksOnBar.isEmpty {
                newTasks.replaceSubrange(0...tasksOnBar.count-1, with: tasksOnBar)
            }
            tasksOnBar = newTasks
        }

        pomoHighlight = Array(repeating: false, count: pomoTimer.order.count)

        if draggableTasksOnBar.count < pomoTimer.order.count {
            (0..<pomoTimer.order.count-draggableTasksOnBar.count).forEach { _ in
                draggableTasksOnBar.append(DraggableTask())
            }
        }
    }

    func addTask(_ text: String, index: Int, context: NSManagedObjectContext) {
        tasksOnBar[index] = text
        saveToUserDefaults()

        if !text.isEmpty && !TasksData.todaysTasksContains(text, context: context) {
            TasksData.addTask(text, order: -1, context: context)
        }
    }

    func renameTask(_ text: String, index: Int, context: NSManagedObjectContext) {
        let oldText = tasksOnBar[index]
        tasksOnBar[index] = text
        saveToUserDefaults()

        if let task = TasksData.taskInTodaysTasks(matching: oldText, context: context) {
            TasksData.editText(text, for: task, context: context)
        }
    }

    func saveToUserDefaults() {
        UserDefaults(suiteName: "group.com.po-gl-a.pomodoro")!.set(tasksOnBar, forKey: "taskNotes")
    }

    func restoreFromUserDefaults() {
        tasksOnBar = UserDefaults(suiteName: "group.com.po-gl-a.pomodoro")!
            .object(forKey: "taskNotes") as? [String] ?? tasksOnBar
        print("RESTORE::tasks=\(tasksOnBar)")
    }
}
