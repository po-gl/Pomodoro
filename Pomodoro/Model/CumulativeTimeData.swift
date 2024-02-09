//
//  CumulativeTimeData.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/5/24.
//

import Foundation
import CoreData
import OSLog

struct CumulativeTimeData {

    static var pastCumulativeTimeRequest: NSFetchRequest<CumulativeTime> {
        let fetchRequest = CumulativeTime.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\CumulativeTime.hourTimestamp, order: .reverse)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        return fetchRequest
    }

    static var thisHourRequest: NSFetchRequest<CumulativeTime> {
        hourRequest(for: Date.now)
    }

    static func hourRequest(for date: Date) -> NSFetchRequest<CumulativeTime> {
        let fetchRequest = CumulativeTime.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\CumulativeTime.hourTimestamp, order: .reverse)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        let startOfHour = Calendar.current.startOfHour(for: date)
        let endOfHour = Calendar.current.date(byAdding: .minute, value: 60, to: startOfHour)!
        fetchRequest.predicate = NSPredicate(
            format: "hourTimestamp >= %@ && hourTimestamp < %@",
            startOfHour as NSDate,
            endOfHour as NSDate
        )
        return fetchRequest
    }

    static func rangeRequest(between range: ClosedRange<Date>) -> NSFetchRequest<CumulativeTime> {
        let fetchRequest = CumulativeTime.fetchRequest()
        fetchRequest.sortDescriptors = [
            SortDescriptor(\CumulativeTime.hourTimestamp, order: .reverse)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        fetchRequest.predicate = NSPredicate(
            format: "hourTimestamp >= %@ && hourTimestamp < %@",
            range.lowerBound as NSDate,
            range.upperBound as NSDate
        )
        return fetchRequest
    }

    static func thisWeeksAverages(context: NSManagedObjectContext) -> [PomoStatus: Double] {
        let startOfWeek = Date.now.startOfWeek
        let endOfWeek = startOfWeek.endOfWeek
        let times = try? context.fetch(CumulativeTimeData.rangeRequest(between: startOfWeek...endOfWeek))
        guard let times else { return [:] }

        var totals = [PomoStatus: Double]()
        times.forEach {
            totals[.work, default: 0] += $0.work
            totals[.rest, default: 0] += $0.rest
            totals[.longBreak, default: 0] += $0.longBreak
        }

        var uniqueDates = Set<Date>()
        times.forEach {
            guard let hourTimestamp = $0.hourTimestamp else { return }
            let startOfDay = hourTimestamp.startOfDay
            uniqueDates.insert(startOfDay)
        }
        return totals.mapValues { $0 / Double(uniqueDates.count) }
    }

    static func addTime(work: Double = 0.0,
                        rest: Double = 0.0,
                        longBreak: Double = 0.0,
                        date: Date = Date(),
                        context: NSManagedObjectContext) {
        let request = date == Date() ? thisHourRequest : hourRequest(for: date)
        if let existingTimeForHour = try? context.fetch(request).first {
            existingTimeForHour.work += work
            existingTimeForHour.rest += rest
            existingTimeForHour.longBreak += longBreak
            
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("dd hh:mm:ss")
        } else {
            let newTime = CumulativeTime(context: context)
            newTime.work = work
            newTime.rest = rest
            newTime.longBreak = longBreak
            newTime.hourTimestamp = Calendar.current.startOfHour(for: date)
        }
        saveContextSync(context, errorMessage: "CoreData error adding cumulative time.")
    }

    static func delete(_ time: CumulativeTime, context: NSManagedObjectContext) {
        context.delete(time)
        saveContext(context, errorMessage: "CoreData error deleting cumulative time.")
    }

    // MARK: Save Context

    static func saveContext(_ context: NSManagedObjectContext, errorMessage: String = "CoreData error.") {
        context.perform {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                Errors.shared.coreDataError = error
                Logger().error("\(errorMessage): \(error), \(error.userInfo)")
            }
        }
    }

    static func saveContextSync(_ context: NSManagedObjectContext, errorMessage: String = "CoreData error.") {
        do {
            try context.save()
        } catch {
            let error = error as NSError
            Errors.shared.coreDataError = error
            Logger().error("Synchronous \(errorMessage): \(error), \(error.userInfo)")
        }
    }
}
