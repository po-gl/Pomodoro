//
//  Migrations.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/7/24.
//

import Foundation
import CoreData
import OSLog

class Migrations {
    static func performTimestampDayMigrationIfNeeded(context: NSManagedObjectContext) {
        let hasPerformedMigration = UserDefaults.standard.bool(forKey: "hasPerformedTimestampDayMigration")
        if !hasPerformedMigration {
            let fetchRequest = TaskNote.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "timestampDay == nil")
            do {
                let tasks = try context.fetch(fetchRequest)
                for taskNote in tasks {
                    if let timestamp = taskNote.timestamp {
                        taskNote.timestampDay = TaskNote.timestampDayFormatter.string(from: timestamp)
                    }
                }
                try context.save()

                UserDefaults.standard.set(true, forKey: "hasPerformedTimestampDayMigration")
            } catch {
                let error = error as NSError
                Errors.shared.coreDataError = error
                Logger().error("CoreData timestampDay migration error: \(error)")
            }
        }
    }
}
