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
        
        ProjectsData.addProject("Work", progress: 1.0, context: viewContext)
        ProjectsData.addProject("Cooking", progress: 0.5, context: viewContext)
        ProjectsData.addProject("Apps", progress: 0.0, context: viewContext)
        ProjectsData.addProject("School", progress: 1.0, archived: true, context: viewContext)
        
        for i in 0..<6 {
            TasksData.addTask("Task \(i)", completed: i == 3 ? true : false, date: Date() - 5, context: viewContext)
        }
        for i in 0..<3 {
            TasksData.addTask("Next day \(i)", date: Date() - 90000, context: viewContext)
        }
        
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Pomodoro")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
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
