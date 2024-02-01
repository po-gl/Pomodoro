//
//  Persistence.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import CoreData
import OSLog

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        var assignedProjects = Set<Project>()

        ProjectsData.addProject("Work", note: "Let apple fix Lists", progress: 1.0, color: "BarRest",
                                date: Date() - 5, context: viewContext)
        let extraProject = ProjectsData.addProject("Cooking", progress: 0.5, color: "BarWork",
                                    date: Date() - 5, context: viewContext)
        assignedProjects.insert(
            ProjectsData.addProject("Apps", progress: 0.0, color: "BarLongBreak",
                                    date: Date() - 5, context: viewContext)
        )
        assignedProjects.insert(
            ProjectsData.addProject("School", progress: 1.0, archivedDate: Date.now,
                                    date: Date() - 5, context: viewContext)
        )

        for i in 0..<6 {
            TasksData.addTask("Task \(i)",
                              completed: i == 3 ? true : false,
                              flagged: i == 1 ? true : false,
                              pomosEstimate: i == 1 || i == 2 ? 3 : -1,
                              pomosActual: i == 2 || i == 3 || i == 4 ? 4 : -1,
                              date: Date() - 5,
                              projects: i == 0 ? assignedProjects.union([extraProject]) : assignedProjects,
                              context: viewContext)
        }
        for i in 0..<3 {
            TasksData.addTask("Next day \(i)", date: Date() - 90000, context: viewContext)
        }

        for i in 0..<3 {
            TasksData.addTask("Next next day \(i)", date: Date() - 200000, context: viewContext)
        }

        for i in 0..<3 {
            TasksData.addTask("14 days ago \(i)", date: Date() - 1209600, context: viewContext)
        }

        for i in 0..<3 {
            TasksData.addTask("2 months ago \(i)", date: Date() - 5259486, context: viewContext)
        }

        for i in 0..<3 {
            TasksData.addTask("7 months ago \(i)", date: Date() - 18408201, context: viewContext)
        }

        for i in 0..<3 {
            TasksData.addTask("1 year ago \(i)", date: Date() - 34186659, context: viewContext)
        }

        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Pomodoro")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                Errors.shared.coreDataError = error
                Logger().error("CoreData error: \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        if !inMemory {
            Migrations.performTimestampDayMigrationIfNeeded(context: container.viewContext)
        }
    }
}
