//
//  ProjectsData.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import Foundation
import CoreData
import OSLog

struct ProjectsData {

    static var currentProjectsRequest: NSFetchRequest<Project> {
        let fetchRequest = Project.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\Project.order, order: .forward),
            SortDescriptor(\Project.timestamp, order: .forward)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "archivedDate == nil"
        )
        return fetchRequest
    }

    static var archivedProjectsRequest: NSFetchRequest<Project> {
        let fetchRequest = Project.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\Project.order, order: .forward),
            SortDescriptor(\Project.archivedDate, order: .reverse)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "archivedDate != nil"
        )
        return fetchRequest
    }

    @discardableResult
    static func addProject(_ name: String,
                           note: String = "",
                           progress: Double = 0.0,
                           color: String? = nil,
                           archivedDate: Date? = nil,
                           order: Int16 = 0,
                           date: Date = Date(),
                           context: NSManagedObjectContext) -> Project {
        let newProject = Project(context: context)
        newProject.name = name
        newProject.note = note
        newProject.progress = progress
        newProject.color = color != nil ? color : Project.colorStrings.randomElement()
        newProject.timestamp = date
        newProject.archivedDate = archivedDate
        newProject.order = order

        try? context.obtainPermanentIDs(for: [newProject])
        saveContext(context, errorMessage: "CoreData error adding project.")
        return newProject
    }

    static func edit(_ name: String,
                     note: String? = nil,
                     progress: Double? = nil,
                     color: String? = nil,
                     archivedDate: Date? = nil,
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
        if let archivedDate {
            project.archivedDate = archivedDate
        }
        updateRelationships(project)
        saveContext(context, errorMessage: "CoreData error editing project.")
    }

    static func editNote(_ note: String, for project: Project, context: NSManagedObjectContext) {
        project.note = note
        updateRelationships(project)
        saveContext(context, errorMessage: "CoreData error editing project note.")
    }

    static func setColor(_ colorName: String, for project: Project, context: NSManagedObjectContext) {
        project.color = colorName
        updateRelationships(project)
        saveContext(context, errorMessage: "CoreData error setting project color.")
    }

    static func setProgress(_ progress: Double, for project: Project, context: NSManagedObjectContext) {
        project.progress = progress
        updateRelationships(project)
        saveContext(context, errorMessage: "CoreData error setting project progress.")
    }

    static func archive(_ project: Project, context: NSManagedObjectContext) {
        project.archivedDate = Date.now
        updateRelationships(project)
        saveContext(context, errorMessage: "CoreData error archiving project.")
    }

    static func toggleArchive(_ project: Project, context: NSManagedObjectContext) {
        if project.archivedDate != nil {
            project.archivedDate = nil
        } else {
            project.archivedDate = Date.now
        }
        updateRelationships(project)
        saveContext(context, errorMessage: "CoreData error toggle archive project.")
    }

    static func delete(_ project: Project, context: NSManagedObjectContext) {
        context.delete(project)
        updateRelationships(project)
        saveContext(context, errorMessage: "CoreData error deleting project.")
    }

    static private func updateRelationships(_ project: Project) {
        for taskNote in project.tasks?.allObjects as? [TaskNote] ?? [] {
            taskNote.objectWillChange.send()
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
                Logger().error("\(errorMessage) :  \(error), \(error.userInfo)")
            }
        }
    }

    static func saveContextSync(_ context: NSManagedObjectContext, errorMessage: String = "CoreData error.") {
        do {
            try context.save()
        } catch {
            let error = error as NSError
            Errors.shared.coreDataError = error
            Logger().error("\(errorMessage) (synchronous) :  \(error), \(error.userInfo)")
        }
    }

    static func getTopProject(context: NSManagedObjectContext) -> Project? {
        guard let currentProjects = try? context.fetch(currentProjectsRequest) else { return nil }
        return currentProjects.first
    }

    static func setAsTopProject(_ project: Project, context: NSManagedObjectContext) {
        if let currentProjects = try? context.fetch(currentProjectsRequest) {
            let oldOrder = project.order
            for project in currentProjects {
                if project.order < oldOrder {
                    project.order += 1
                } else {
                    break
                }
            }
            project.order = 0
            saveContextSync(context, errorMessage: "CoreData error setting project as top.")
        }
    }

    static func setOrderWithoutSaving(_ order: Int, for project: Project, context: NSManagedObjectContext) {
        project.order = Int16(order)
    }
}

extension Project {
    public var tasksArray: [TaskNote] {
        get async {
            let sortDescriptors = [NSSortDescriptor(keyPath: \TaskNote.timestamp, ascending: false)]
            return self.tasks?.sortedArray(using: sortDescriptors) as? [TaskNote] ?? []
        }
    }

    static let colorStrings: [String] = ["BarRest", "BarWork", "BarLongBreak", "End", "AccentColor"]
}
