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
#if DEBUG
    static var shared: PersistenceController = {
        if ProcessInfo.processInfo.arguments.contains("-usePreviewData") {
            return preview
        }
        return PersistenceController()
    }()
#else
    static var shared = PersistenceController()
#endif

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let previewProjects: [(name: String,
                               note: String,
                               progress: Double,
                               color: String,
                               archiveDate: Date?,
                               date: Date)] =
        [
            ("Veggie Project", "", 0.5, "BarRest", nil, Date.now - 5),
            ("Plant Paper", "a history of abnormal horticulture", 1.0, "BarWork", nil, Date.now - 5),
            ("App", "- design\n- test\n- refine\n- some other steps", 0.0, "BarLongBreak", nil, Date.now - 5),
            ("School", "an archived project", 1.0, "End", Date.now, Date.now - 5)
        ]

        let projects = previewProjects.map {
            ProjectsData.addProject($0.name, note: $0.note, progress: $0.progress,
                                    color: $0.color, archivedDate: $0.archiveDate,
                                    date: $0.date, context: viewContext)
        }

        let p1p3: Set<Project> = [projects[0], projects[2]]
        let p2p4: Set<Project> = [projects[1], projects[3]]
        let p2: Set<Project> = [projects[1]]

        var previewTasks: [(text: String,
                            note: String,
                            completed: Bool,
                            flagged: Bool,
                            estimateActual: (Int, Int),
                            projects: Set<Project>,
                            date: Date)] =
        [
            ("Plan out garden", "", false, false, (1, -1), p1p3, Date.now - 4),
            ("Plant vegetables", "tomatoes, peas, yams, etc.", false, false, (2, -1), p1p3, Date.now - 3),
            ("Make prototype vegetable app", "what would this even be?", false, false, (4, -1), p1p3, Date.now - 2),
            ("Clear out emails", "", true, false, (4, 2), [], Date.now - 1),
            // The next day
            ("Research new recipes", "ideally, ones that use fresh vegetables", true, true, (0, 2), [], Date.now - 3600 * 24 - 1),
            ("Outline paper on abnormal horticulture", "", true, false, (-1, -1), p2p4, Date.now - 3600 * 24 - 2),
            ("First draft of horticulture paper", "", true, false, (2, 4), p2, Date.now - 3600 * 24 - 3),
            ("Daily sketch", "", true, false, (0, 1), [], Date.now - 3600 * 24 - 4),
            ("Review code changes", "", true, false, (0, 4), [], Date.now - 3600 * 24 - 5),
        ]

        previewTasks.append(contentsOf: (0..<4).map { ("2 days ago (\($0))", "", false, false, (-1, -1), Set<Project>(), Date.now - 2 * 24 * 3600) })
        previewTasks.append(contentsOf: (0..<3).map { ("3 days ago (\($0))", "", false, false, (-1, -1), Set<Project>(), Date.now - 3 * 24 * 3600) })
        previewTasks.append(contentsOf: (0..<2).map { ("5 days ago (\($0))", "", false, false, (-1, -1), Set<Project>(), Date.now - 5 * 24 * 3600) })
        previewTasks.append(contentsOf: (0..<3).map { ("14 days ago (\($0))", "", false, false, (-1, -1), Set<Project>(), Date.now - 1209600) })
        previewTasks.append(contentsOf: (0..<3).map { ("2 months ago (\($0))", "", false, false, (-1, -1), Set<Project>(), Date.now - 5259486) })
        previewTasks.append(contentsOf: (0..<3).map { ("7 months ago (\($0))", "", false, false, (-1, -1), Set<Project>(), Date.now - 18408201) })
        previewTasks.append(contentsOf: (0..<3).map { ("1 year ago (\($0))", "", false, false, (-1, -1), Set<Project>(), Date.now - 34186659) })

        previewTasks.forEach {
            TasksData.addTask($0.text, note: $0.note,
                              completed: $0.completed, flagged: $0.flagged,
                              pomosEstimate: Int16($0.estimateActual.0),
                              pomosActual: Int16($0.estimateActual.1),
                              date: $0.date, projects: $0.projects,
                              context: viewContext)
        }

        // Add tasks to progress bar
        let pomoTimer = PomoTimer()
        let tasksOnBar = TasksOnBar.shared
        tasksOnBar.setTaskAmount(for: pomoTimer)
        tasksOnBar.addTask(previewTasks[0].text, index: 0, context: viewContext)
        tasksOnBar.addTask(previewTasks[1].text, index: 2, context: viewContext)

        // Add more typical cumulative times
        CumulativeTimeData.addPreviewTimes(between: Date.now.addingTimeInterval(-4 * 3600)...Date.now, addRandomVariance: true, context: viewContext)
        CumulativeTimeData.addPreviewTimes(between: Date.now.addingTimeInterval(-30 * 3600)...Date.now.addingTimeInterval(-24 * 3600), context: viewContext)

        // Add random distribution of pomodoro estimations
        let tasks = try? viewContext.fetch(TasksData.pastTasksRequest(olderThan: Date.now - 3600 * 24 * 2))
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
            tasks.first?.pomosEstimate = 3
            tasks.first?.pomosActual = 4
        }

        // Add random cumulative times data
        let gaussianDistribution = GKGaussianDistribution(lowestValue: 0, highestValue: 100)
        let startOfDay = Calendar.current.startOfDay(for: Date.now - 3600 * 24 * 2)
        for day in 0..<30 {
            let dayModifier = 1.0 - (Double(gaussianDistribution.nextInt(upperBound: 50)) / 100)
            for i in 0..<24 {
                guard 9 <= i && i <= 17 else { continue }
                let dayDate = Calendar.current.date(byAdding: .day, value: -day, to: startOfDay)!
                let weekDay = Calendar.current.component(.weekday, from: dayDate)
                guard 2 <= weekDay && weekDay <= 6 else { continue }
                let hourDate = Calendar.current.date(byAdding: .hour, value: i, to: dayDate)!
                guard hourDate <= Date.now else { continue }

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
