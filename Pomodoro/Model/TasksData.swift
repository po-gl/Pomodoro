//
//  TasksData.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import CoreData

struct TasksData {
    
    static func addTask(_ text: String,
                        completed: Bool = false,
                        order: Int16 = 0,
                        date: Date = Date(),
                        context: NSManagedObjectContext) {
        let newTask = TaskNote(context: context)
        newTask.text = text
        newTask.completed = completed
        newTask.timestamp = date
        newTask.order = order
        saveContext(context, errorMessage: "CoreData error adding task.")
    }
    
    static func editText(_ text: String, for task: TaskNote, context: NSManagedObjectContext) {
        task.text = text
        saveContext(context, errorMessage: "CoreData error editing task.")
    }
    
    static func toggle(for task: TaskNote, context: NSManagedObjectContext) {
        task.completed.toggle()
        saveContext(context, errorMessage: "CoreData error toggle task completion.")
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
    
    static func sortCompleted(_ tasks: FetchedResults<TaskNote>, context: NSManagedObjectContext) {
        var lastUncompleted = 0
        for task in tasks {
            if !task.completed {
                lastUncompleted = max(lastUncompleted, Int(task.order))
            }
        }
        
        for task in tasks {
            if task.completed {
                if Int(task.order) <= lastUncompleted {
                    task.order = Int16(lastUncompleted + 1)
                }
            }
        }
        
        saveContext(context, errorMessage: "CoreData error sorting tasks by completed.")
    }
    
    static func todaysTasksContains(_ task: String, context: NSManagedObjectContext) -> Bool {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ && timestamp <= %@",
            Calendar.current.startOfDay(for: Date()) as CVarArg,
            Calendar.current.startOfDay(for: Date() + 86400) as CVarArg
        )
        
        let todaysTasks = try? context.fetch(fetchRequest)
        
        return todaysTasks?.contains(where: { $0.text == task }) ?? false
    }
}
