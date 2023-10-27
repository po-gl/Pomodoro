//
//  Persistence.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import CoreData

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
            ProjectsData.addProject("School", progress: 1.0, archived: true,
                                    date: Date() - 5, context: viewContext)
        )

        for i in 0..<6 {
            TasksData.addTask("Task \(i)",
                              completed: i == 3 ? true : false,
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application,
                // although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible,
                 * due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
