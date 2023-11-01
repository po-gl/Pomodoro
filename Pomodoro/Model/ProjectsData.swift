//
//  ProjectsData.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import Foundation
import CoreData

struct ProjectsData {

    static var currentProjectsRequest: NSFetchRequest<Project> {
        let fetchRequest = Project.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\Project.order, order: .forward),
            SortDescriptor(\Project.timestamp, order: .forward)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "archived == false"
        )
        return fetchRequest
    }

    @discardableResult
    static func addProject(_ name: String,
                           note: String = "",
                           progress: Double = 0.0,
                           color: String = "BarRest",
                           archived: Bool = false,
                           order: Int16 = 0,
                           date: Date = Date(),
                           context: NSManagedObjectContext) -> Project {
        let newProject = Project(context: context)
        newProject.name = name
        newProject.note = note
        newProject.progress = progress
        newProject.color = color
        newProject.timestamp = date
        newProject.archived = archived
        newProject.order = order

        try? context.obtainPermanentIDs(for: [newProject])
        saveContext(context, errorMessage: "CoreData error adding project.")
        return newProject
    }

    static func edit(_ name: String,
                     note: String? = nil,
                     progress: Double? = nil,
                     color: String? = nil,
                     archived: Bool? = nil,
                     for project: Project, context: NSManagedObjectContext) {
        project.name = name
        if let note {
            project.note = note
        }
        if let progress {
            project.progress = progress
        }
        if let color {
            project.color = color
        }
        if let archived {
            project.archived = archived
        }
        saveContext(context, errorMessage: "CoreData error editing project.")
    }

    static func editNote(_ note: String, for project: Project, context: NSManagedObjectContext) {
        project.note = note
        saveContext(context, errorMessage: "CoreData error editing project note.")
    }

    static func setColor(_ colorName: String, for project: Project, context: NSManagedObjectContext) {
        project.color = colorName
        saveContext(context, errorMessage: "CoreData error setting project color.")
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

    static func getTopProject(context: NSManagedObjectContext) -> Project? {
        guard let currentProjects = try? context.fetch(currentProjectsRequest) else { return nil }
        return currentProjects.first
    }

    static func setAsTopProject(_ project: Project, context: NSManagedObjectContext) {
        if let currentProjects = try? context.fetch(currentProjectsRequest) {
            for project in currentProjects {
                project.order = 1
            }
            project.order = 0
            saveContext(context, errorMessage: "CoreData error setting project as top.")
        }
    }
}
