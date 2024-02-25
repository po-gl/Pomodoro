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
    
    static var latestTimeRequest: NSFetchRequest<CumulativeTime> {
        let fetchRequest = pastCumulativeTimeRequest
        fetchRequest.fetchLimit = 1
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
        if let existingTime = try? context.fetch(request).first {
            guard 3600 >= existingTime.work + work + existingTime.rest + rest + existingTime.longBreak + longBreak else {
                Logger().error("Cumulative time overflow")
                return
            }
            existingTime.work += work
            existingTime.rest += rest
            existingTime.longBreak += longBreak
        } else {
            guard 3600 >= work + rest + longBreak else {
                Logger().error("Cumulative time overflow")
                return
            }
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

    static func deleteAll(context: NSManagedObjectContext) {
        let times = try? context.fetch(CumulativeTimeData.pastCumulativeTimeRequest)
        guard let times else { return }
        for time in times {
            context.delete(time)
        }
        saveContext(context, errorMessage: "CoreData error deleting all cumulative times.")
    }

    // MARK: Save Context

    static func saveContext(_ context: NSManagedObjectContext, errorMessage: String = "CoreData error.") {
        context.perform {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                Errors.shared.coreDataError = error
                Logger().error("\(errorMessage) : \(error), \(error.userInfo)")
            }
        }
    }

    static func saveContextSync(_ context: NSManagedObjectContext, errorMessage: String = "CoreData error.") {
        do {
            try context.save()
        } catch {
            let error = error as NSError
            Errors.shared.coreDataError = error
            Logger().error("\(errorMessage) (synchronous) : \(error), \(error.userInfo)")
        }
    }

    static func addPreviewTimes(between: ClosedRange<Date>, addRandomVariance: Bool = false, context: NSManagedObjectContext) {
        let patternVariance = addRandomVariance ? Double.random(in: 1.0...8.0) : 0.0
        let pattern: [(PomoStatus, TimeInterval)] = [
            (.work, PomoTimer.defaultWorkTime + (patternVariance * 60)),
            (.rest, PomoTimer.defaultRestTime + (patternVariance / 2 * 60)),
            (.work, PomoTimer.defaultWorkTime + (patternVariance * 60)),
            (.rest, PomoTimer.defaultRestTime + (patternVariance / 2 * 60)),
            (.longBreak, PomoTimer.defaultBreakTime),
        ]
        var times = [(PomoStatus, TimeInterval)]()

        var i = 0
        var date = between.lowerBound.startOfHour
        var hourAccumulator = 0.0
        while date < between.upperBound.startOfHour {
            let startOfHour = date.startOfHour

            let timeToAdd = pattern[i % pattern.count].1
            times.append(pattern[i % pattern.count])
            hourAccumulator += timeToAdd

            if hourAccumulator > 3600 {
                let excess = hourAccumulator.truncatingRemainder(dividingBy: 3600)
                times[times.count-1].1 -= excess

                let workTime = times.reduce(0.0, { $0 + ($1.0 == .work ? $1.1 : 0.0)})
                let restTime = times.reduce(0.0, { $0 + ($1.0 == .rest ? $1.1 : 0.0)})
                let breakTime = times.reduce(0.0, { $0 + ($1.0 == .longBreak ? $1.1 : 0.0)})
                CumulativeTimeData.addTime(work: workTime, rest: restTime, longBreak: breakTime,
                                           date: startOfHour, context: context)

                let endStatus = times[times.count-1].0
                times = []
                hourAccumulator -= 3600
                times.append((status: endStatus, time: excess))  // add back excess
            }
            i += 1
            date.addTimeInterval(timeToAdd)
        }
        let workTime = times.reduce(0.0, { $0 + ($1.0 == .work ? $1.1 : 0.0)})
        let restTime = times.reduce(0.0, { $0 + ($1.0 == .rest ? $1.1 : 0.0)})
        let breakTime = times.reduce(0.0, { $0 + ($1.0 == .longBreak ? $1.1 : 0.0)})
        CumulativeTimeData.addTime(work: workTime, rest: restTime, longBreak: breakTime,
                                   date: between.upperBound, context: context)
    }
}
