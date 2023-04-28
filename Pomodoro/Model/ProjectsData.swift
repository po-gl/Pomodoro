//
//  ProjectsData.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import Foundation
import CoreData

struct ProjectsData {
    
    static func addProject(_ name: String,
                           progress: Double = 0.0,
                           archived: Bool = false,
                           order: Int16 = 0,
                           date: Date = Date(),
                           context: NSManagedObjectContext) {
        let newProject = Project(context: context)
        newProject.name = name
        newProject.progress = progress
        newProject.timestamp = date
        newProject.archived = archived
        newProject.order = order
        saveContext(context, errorMessage: "CoreData error adding project.")
    }
    
    static func editName(_ name: String, for task: Project, context: NSManagedObjectContext) {
        task.name = name
        saveContext(context, errorMessage: "CoreData error editing project.")
    }
    
    static func setProgress(_ progress: Double, for project: Project, context: NSManagedObjectContext) {
        project.progress = progress
        saveContext(context, errorMessage: "CoreData error setting project progress.")
    }
    
    static func archive(_ project: Project, context: NSManagedObjectContext) {
        project.archived = true
        saveContext(context, errorMessage: "CoreData error archiving project.")
    }
    
    static func toggleArchive(_ project: Project, context: NSManagedObjectContext) {
        project.archived.toggle()
        saveContext(context, errorMessage: "CoreData error toggle archive project.")
    }
    
    static func delete(_ project: Project, context: NSManagedObjectContext) {
        context.delete(project)
        saveContext(context, errorMessage: "CoreData error deleting project.")
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
}
