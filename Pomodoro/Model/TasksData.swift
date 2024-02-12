//
//  TasksData.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import CoreData
import OSLog

struct TasksData {

    static var todaysTasksRequest: NSFetchRequest<TaskNote> {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\TaskNote.order, order: .reverse),
            SortDescriptor(\TaskNote.timestamp, order: .forward)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        let startOfDay = Calendar.current.startOfDay(for: Date.now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ && timestamp <= %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        return fetchRequest
    }

    static var pastTasksRequest: NSFetchRequest<TaskNote> {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\TaskNote.timestampDay, order: .reverse),
            SortDescriptor(\TaskNote.completed, order: .forward)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "timestamp < %@",
            Calendar.current.startOfDay(for: Date()) as CVarArg
        )
        return fetchRequest
    }

    static var yesterdaysTasksRequest: NSFetchRequest<TaskNote> {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\TaskNote.order, order: .reverse),
            SortDescriptor(\TaskNote.timestamp, order: .forward)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        let startOfToday = Calendar.current.startOfDay(for: Date.now)
        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: startOfToday)!
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ && timestamp < %@",
            startOfYesterday as NSDate,
            startOfToday as NSDate
        )
        return fetchRequest
    }

    static var limitedPastTasksRequest: NSFetchRequest<TaskNote> {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\TaskNote.timestamp, order: .reverse)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "timestamp < %@",
            Calendar.current.startOfDay(for: Date()) as CVarArg
        )
        fetchRequest.fetchLimit = 50
        return fetchRequest
    }

    static var latestTask: NSFetchRequest<TaskNote> {
        let fetchRequest = pastTasksRequest(olderThan: Date.now)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    static func pastTasksRequest(olderThan date: Date) -> NSFetchRequest<TaskNote> {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\TaskNote.timestamp, order: .reverse)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "timestamp < %@",
            date as NSDate
        )
        return fetchRequest
    }

    static func rangeRequest(between range: ClosedRange<Date>) -> NSFetchRequest<TaskNote> {
        let fetchRequest = TaskNote.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\TaskNote.timestamp, order: .reverse)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ && timestamp < %@",
            range.lowerBound as NSDate,
            range.upperBound as NSDate
        )
        return fetchRequest
    }

    static func addTask(_ text: String,
                        note: String = "",
                        completed: Bool = false,
                        flagged: Bool = false,
                        pomosEstimate: Int16 = -1,
                        pomosActual: Int16 = -1,
                        order: Int16 = 0,
                        date: Date = Date(),
                        projects: Set<Project> = [],
                        context: NSManagedObjectContext) {
        let newTask = TaskNote(context: context)
        newTask.text = text
        newTask.note = note
        newTask.completed = completed
        newTask.flagged = flagged
        newTask.pomosEstimate = pomosEstimate
        newTask.pomosActual = pomosActual
        newTask.order = order
        newTask.timestamp = date
        newTask.timestampDay = TaskNote.timestampDayFormatter.string(from: date)
        newTask.projects = projects as NSSet

        try? context.obtainPermanentIDs(for: [newTask])
        updateRelationships(newTask)
        saveContext(context, errorMessage: "CoreData error adding task.")
    }

    static func edit(_ text: String,
                     note: String? = nil,
                     completed: Bool? = nil,
                     flagged: Bool? = nil,
                     pomosEstimate: Int16? = nil,
                     pomosActual: Int16? = nil,
                     projects: Set<Project>? = nil,
                     for task: TaskNote,
                     context: NSManagedObjectContext) {
        task.text = text
        if let note {
            task.note = note
        }
        if let completed {
            task.completed = completed
        }
        if let flagged {
            task.flagged = flagged
        }
        if let pomosEstimate {
            task.pomosEstimate = pomosEstimate
        }
        if let pomosActual {
            task.pomosActual = pomosActual
        }
        if let projects {
            task.projects = projects as NSSet
        }
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error editing task text.")
    }

    static func editNote(_ note: String, for task: TaskNote, context: NSManagedObjectContext) {
        task.note = note
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error editing task note.")
    }

    static func toggleCompleted(for task: TaskNote, context: NSManagedObjectContext) {
        task.completed.toggle()
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error toggle task completion.")
    }

    static func setCompleted(for task: TaskNote, context: NSManagedObjectContext) {
        task.completed = true
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error setting task completion to true.")
    }

    static func toggleFlagged(for task: TaskNote, context: NSManagedObjectContext) {
        task.flagged.toggle()
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error toggle task flagging.")
    }

    static func add(project: Project, for task: TaskNote, context: NSManagedObjectContext) {
        task.addToProjects(project)
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error assigning project to task note.")
    }

    static func remove(project: Project, for task: TaskNote, context: NSManagedObjectContext) {
        task.removeFromProjects(project)
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error removing project assignment from task note.")
    }

    static func delete(_ task: TaskNote, context: NSManagedObjectContext) {
        context.delete(task)
        updateRelationships(task)
        saveContext(context, errorMessage: "CoreData error deleting task.")
    }

    /// Returns count of deleted tasks
    static func deleteOlderThanToday(context: NSManagedObjectContext) throws -> Int {
        guard let tasksToDelete = try? context.fetch(pastTasksRequest)
        else { throw TasksDataError.failedFetch }
        let tasksDeleted = tasksToDelete.count

        for task in tasksToDelete {
            context.delete(task)
            updateRelationships(task)
        }
        saveContext(context, errorMessage: "CoreData error deleting tasks older than today.")
        return tasksDeleted
    }

    /// Returns count of deleted tasks
    static func deleteOlderThan(_ component: Calendar.Component, value: Int, context: NSManagedObjectContext) throws -> Int {
        guard let date = Calendar.current.date(byAdding: component, value: -value, to: Date.now)
        else { throw TasksDataError.failedDateCreation }

        guard let tasksToDelete = try? context.fetch(pastTasksRequest(olderThan: date))
        else { throw TasksDataError.failedFetch }
        let tasksDeleted = tasksToDelete.count

        for task in tasksToDelete {
            context.delete(task)
            updateRelationships(task)
        }
        saveContext(context, errorMessage: "CoreData error deleting tasks older than date.")
        return tasksDeleted
    }

    static func duplicate(_ task: TaskNote,
                          text: String? = nil,
                          note: String? = nil,
                          completed: Bool? = nil,
                          flagged: Bool? = nil,
                          pomosEstimate: Int16? = nil,
                          pomosActual: Int16? = nil,
                          order: Int16? = nil,
                          date: Date? = nil,
                          projects: Set<Project>? = nil,
                          context: NSManagedObjectContext) {
        TasksData.addTask(text ?? task.text ?? "",
                          note: note ?? task.note ?? "",
                          completed: completed ?? task.completed,
                          flagged: flagged ?? task.flagged,
                          pomosEstimate: pomosEstimate ?? task.pomosEstimate,
                          pomosActual: pomosActual ?? task.pomosActual,
                          order: order ?? task.order,
                          date: date ?? task.timestamp ?? Date(),
                          projects: projects ?? task.projects as? Set<Project> ?? [],
                          context: context)
    }

    static private func updateRelationships(_ task: TaskNote) {
        for project in task.projects?.allObjects as? [Project] ?? [] {
            project.objectWillChange.send()
        }
    }

    // MARK: Save Context

    static func saveContext(_ context: NSManagedObjectContext, errorMessage: String = "CoreData error.") {
        context.perform {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                Errors.shared.coreDataError = error
                Logger().error("\(#line) CoreData error: \(error), \(error.userInfo)")
            }
        }
    }

    static func separateCompleted(_ tasks: some Sequence<TaskNote>, context: NSManagedObjectContext) {
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

    static func thisWeeksEstimateAverages(context: NSManagedObjectContext) -> (estimate: Double?, actual: Double?) {
        let startOfWeek = Date.now.startOfWeek
        let endOfWeek = startOfWeek.endOfWeek
        let tasks = try? context.fetch(TasksData.rangeRequest(between: startOfWeek...endOfWeek))
        guard let tasks else { return (0, 0) }
        var tasksByRange = (estimate: 0, actual: 0, estimateCount: 0, actualCount: 0)
        tasks.forEach {
            if $0.pomosEstimate > 0 {
                tasksByRange.estimate += Int($0.pomosEstimate)
                tasksByRange.estimateCount += 1
            }
            if $0.pomosActual > 0 && $0.completed {
                tasksByRange.actual += Int($0.pomosActual)
                tasksByRange.actualCount += 1
            }
        }
        let averageEstimate = tasksByRange.estimateCount == 0 ? nil : Double(tasksByRange.estimate) / Double(tasksByRange.estimateCount)
        let averageActual = tasksByRange.actualCount == 0 ? nil : Double(tasksByRange.actual) / Double(tasksByRange.actualCount)
        return (estimate: averageEstimate, actual: averageActual)
    }

    static func thisWeeksCompletedData(context: NSManagedObjectContext) -> (count: Int, average: Double) {
        let startOfWeek = Date.now.startOfWeek
        let endOfWeek = startOfWeek.endOfWeek
        let tasks = try? context.fetch(TasksData.rangeRequest(between: startOfWeek...endOfWeek))
        guard let tasks else { return (0, 0) }

        let countOfTasks = tasks.reduce(0, { $0 + ($1.completed ? 1 : 0) })
        let countOfDays = ceil(min(7, Date.now.timeIntervalSince(Date.now.startOfWeek) / (3600 * 24)))
        guard countOfDays > 0 else { return (0, 0) }
        return (count: countOfTasks, average: Double(countOfTasks) / countOfDays)
    }
}

enum TasksDataError: Error {
    case failedFetch
    case failedDateCreation
}

extension TaskNote {

    override public func willSave() {
        super.willSave()

        if let timestamp = self.timestamp, self.changedValues()["timestamp"] != nil && self.changedValues()["timestampDay"] == nil {
            self.timestampDay = TaskNote.timestampDayFormatter.string(from: timestamp)
        }
    }

    public var projectsArray: [Project] {
        let set = projects as? Set<Project> ?? []
        return set.sorted {
            $0.name ?? "" < $1.name ?? ""
        }
    }

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

    static let timestampDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
