//
//  TasksData.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import CoreData

struct TasksData {

    static var todaysTasksRequest: NSFetchRequest<TaskNote> {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ && timestamp <= %@",
            Calendar.current.startOfDay(for: Date()) as CVarArg,
            Calendar.current.startOfDay(for: Date() + 86400) as CVarArg
        )
        return fetchRequest
    }

    static func addTask(_ text: String,
                        note: String = "",
                        completed: Bool = false,
                        flagged: Bool = false,
                        order: Int16 = 0,
                        date: Date = Date(),
                        context: NSManagedObjectContext) {
        let newTask = TaskNote(context: context)
        newTask.text = text
        newTask.note = note
        newTask.completed = completed
        newTask.flagged = flagged
        newTask.timestamp = date
        newTask.order = order

        try? context.obtainPermanentIDs(for: [newTask])
        saveContext(context, errorMessage: "CoreData error adding task.")
    }

    static func editText(_ text: String, for task: TaskNote, context: NSManagedObjectContext) {
        task.text = text
        saveContext(context, errorMessage: "CoreData error editing task.")
    }

    static func editNote(_ note: String, for task: TaskNote, context: NSManagedObjectContext) {
        task.note = note
        saveContext(context, errorMessage: "CoreData error editing task note.")
    }

    static func toggleCompleted(for task: TaskNote, context: NSManagedObjectContext) {
        task.completed.toggle()
        saveContext(context, errorMessage: "CoreData error toggle task completion.")
    }

    static func setCompleted(for task: TaskNote, context: NSManagedObjectContext) {
        task.completed = true
        saveContext(context, errorMessage: "CoreData error setting task completion to true.")
    }

    static func toggleFlagged(for task: TaskNote, context: NSManagedObjectContext) {
        task.flagged.toggle()
        saveContext(context, errorMessage: "CoreData error toggle task flagging.")
    }

    static func delete(_ task: TaskNote, context: NSManagedObjectContext) {
        context.delete(task)
        saveContext(context, errorMessage: "CoreData error deleting task.")
    }

    // MARK: Save Context

    static func saveContext(_ context: NSManagedObjectContext, errorMessage: String = "CoreData error.") {
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("\(errorMessage) \(nsError), \(nsError.userInfo)")
        }
    }

    static func separateCompleted(_ tasks: FetchedResults<TaskNote>, context: NSManagedObjectContext) {
        let countOfUncompleted = tasks.filter { !$0.completed }.count

        // O(n) iterate through array, maintain two indexes
        // - one for noncompleted starting at countOfNoncompleted-1 to 0
        // - one for completed starting at -1 to -countOfCompleted
        // 4 3 2 1 0 -1 -2
        var uncompleteOrder = countOfUncompleted-1  // to 0
        var completeOrder = -1  // to -countOfCompleted
        for task in tasks {
            if !task.completed {
                task.order = Int16(uncompleteOrder)
                uncompleteOrder -= 1
            } else {
                task.order = Int16(completeOrder)
                completeOrder -= 1
            }
        }

        saveContext(context, errorMessage: "CoreData error sorting tasks by completed.")
    }

    static func todaysTasksContains(_ task: String, context: NSManagedObjectContext) -> Bool {
        let todaysTasks = try? context.fetch(todaysTasksRequest)
        return todaysTasks?.contains(where: { $0.text == task }) ?? false
    }

    static func taskInTodaysTasks(matching text: String, context: NSManagedObjectContext) -> TaskNote? {
        let todaysTasks = try? context.fetch(todaysTasksRequest)
        return todaysTasks?.first(where: { $0.text == text })
    }

}

extension TaskNote {
    @objc
    public var section: String {
        if let timestamp {
            return TaskNote.sectionFormatter.string(from: timestamp)
        }
        return "undated"
    }

    static let sectionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d y")
        return formatter
    }()
}
