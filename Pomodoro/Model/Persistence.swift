//
//  Persistence.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import CoreData
import GameplayKit
import OSLog

struct PersistenceController {
    static var shared: PersistenceController = {
        if ProcessInfo.processInfo.arguments.contains("-isUITest") {
            return preview
        }
        return PersistenceController()
    }()

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
                              completed: i < 3 ? true : false,
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
        
        // Add random distribution of pomodoro estimations
        let tasks = try? viewContext.fetch(TasksData.pastTasksRequest(olderThan: Date.now))
        let estimationGaussianDistribution = GKGaussianDistribution(lowestValue: 0, highestValue: 7)
        let actualGaussianDistribution = GKGaussianDistribution(lowestValue: 0, highestValue: 7)
        if let tasks {
            for taskItem in tasks {
                let estimationSample = estimationGaussianDistribution.nextInt()
                let actualSample = actualGaussianDistribution.nextInt()
                if estimationSample != 7 {
                    taskItem.pomosEstimate = Int16(estimationSample)
                }
                if actualSample != 7 {
                    taskItem.pomosActual = Int16(actualSample)
                }
                if Bool.random() && taskItem.timestamp ?? Date.now < Date.now.startOfDay {
                    taskItem.completed = true
                }
            }
        }

        // Add cumulative times data
        let gaussianDistribution = GKGaussianDistribution(lowestValue: 0, highestValue: 100)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        for day in 0..<30 {
            let dayModifier = 1.0 - (Double(gaussianDistribution.nextInt(upperBound: 50)) / 100)
            for i in 0..<24 {
                if i > 2 && i < 10 { continue }
                let dayDate = Calendar.current.date(byAdding: .day, value: -day, to: startOfDay)!
                let hourDate = Calendar.current.date(byAdding: .hour, value: i, to: dayDate)!
                if hourDate > Date.now { continue }

                let work = Double(gaussianDistribution.nextInt()) * (i % 7 != 0 ? 0.50 : 0.15) * dayModifier
                let rest = Double(gaussianDistribution.nextInt()) * (i % 7 != 0 ? 0.10 : 0.05) * dayModifier
                let longBreak = Double(gaussianDistribution.nextInt()) * (i % 7 == 0 ? 0.40 : 0.0) * dayModifier
                CumulativeTimeData.addTime(work: work*60, rest: rest*60, longBreak: longBreak*60,
                                           date: hourDate, context: viewContext)
            }
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
