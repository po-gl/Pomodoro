//
//  TaskNotes.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/10/23.
//

import SwiftUI
import CoreData
import OSLog

class TasksOnBar: ObservableObject {
    static let shared = TasksOnBar()

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

    func addTask(_ text: String, index: Int, context: NSManagedObjectContext?) {
        tasksOnBar[index] = text

        if let context {
            saveToUserDefaults()

            if !text.isEmpty && !TasksData.todaysTasksContains(text, context: context) {
                TasksData.addTask(text, order: -1, context: context)
            }
        }
    }

    @discardableResult
    func addTaskFromList(_ text: String, context: NSManagedObjectContext) -> Bool {
        guard !text.isEmpty else { return false }
        
        for i in tasksOnBar.indices {
            if isWorkIndex(i) && tasksOnBar[i] == "" {
                tasksOnBar[i] = text
                saveToUserDefaults()
                return true
            }
        }
        return false
    }

    @discardableResult
    func removeTaskFromList(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        guard tasksOnBar.contains(where: { $0 == text }) else { return false }

        tasksOnBar = tasksOnBar.map { $0 == text ? "" : $0 }
        return true
    }

    func isOnBar(_ text: String) -> Bool {
        return tasksOnBar.contains(where: { $0 == text })
    }

    private func isWorkIndex(_ index: Int) -> Bool {
        return index % 2 == 0 && index < tasksOnBar.count-2
    }

    func renameTask(_ text: String, index: Int, context: NSManagedObjectContext) {
        let oldText = tasksOnBar[index]
        tasksOnBar[index] = text
        saveToUserDefaults()

        if let task = TasksData.taskInPastMonth(matching: oldText, context: context) {
            TasksData.edit(text, for: task, context: context)
        }
    }

    func saveToUserDefaults() {
        UserDefaults.pomo?.set(tasksOnBar, forKey: "taskNotes")
    }

    func restoreFromUserDefaults(with pomoTimer: PomoTimer) {
        tasksOnBar = UserDefaults.pomo?.object(forKey: "taskNotes") as? [String] ?? tasksOnBar
        Logger().log("RESTORE::tasks=\(self.tasksOnBar)")
        setTaskAmount(for: pomoTimer)
    }
}
