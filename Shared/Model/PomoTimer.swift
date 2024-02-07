//
//  PomoTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI
import CoreData
import OSLog

class PomoTimer: SequenceTimer {
    @Published var order: [PomoTime]
    @Published var pomoCount: Int
    @Published var status: PomoStatus

    var workDuration: Double
    var restDuration: Double
    var breakDuration: Double

    private let maxPomos: Int = 6

    static let defaultWorkTime: Double = 25.0 * 60.0
    static let defaultRestTime: Double = 5.0 * 60.0
    static let defaultBreakTime: Double = 30.0 * 60.0

    private var pomoAction: (PomoStatus) -> Void

    var lastRecordedAt: Date?
    var context: NSManagedObjectContext?

    init(pomos: Int = 4,
         work: Double = defaultWorkTime,
         rest: Double = defaultRestTime,
         longBreak: Double = defaultBreakTime,
         context: NSManagedObjectContext? = nil,
         perform action: @escaping (PomoStatus) -> Void = { _ in return },
         timeProvider: Timer.Type = Timer.self) {
        pomoCount = pomos
        workDuration = work
        restDuration = rest
        breakDuration = longBreak
        self.context = context
        pomoAction = action
        let pomoTimes = getPomoTimes(pomos, work, rest, longBreak)
        let timeIntervals = pomoTimes.map { $0.timeInterval }
        order = pomoTimes
        status = pomoTimes.first?.status ?? .work

        weak var selfInstance: PomoTimer?
        super.init(timeIntervals, perform: { index in
            if index < pomoTimes.count {
                selfInstance?.status = pomoTimes[index].status
                action(pomoTimes[index].status)
            } else {
                selfInstance?.status = .end
                action(.end)
                withAnimation {
                    selfInstance?.toggleAndRecord()
                }
            }
        }, timerProvider: timeProvider)
        selfInstance = self
    }

    public func getStatus(atDate: Date = Date()) -> PomoStatus {
        let index = getIndex(atDate: atDate)
        if index == order.count-1 && timeRemaining(atDate: atDate) == 0.0 {
            return .end
        }
        return order[index].status
    }

    public func getProgress(atDate: Date = Date()) -> Double {
        let index = getIndex(atDate: atDate)
        let intervals = order.map { $0.timeInterval }
        let total = intervals.reduce(0, +)
        var cumulative = 0.0
        for i in 0..<index {
           cumulative += intervals[i]
        }
        let currentTime = intervals[index] - floor(timeRemaining(atDate: atDate))
        let progress = (cumulative + currentTime) / total
        return progress <= 1.0 ? progress : 1.0
    }

    public override func setPercentage(to percent: Double) {
        self.reset(pomos: pomoCount,
                   work: workDuration,
                   rest: restDuration,
                   longBreak: breakDuration)
        super.setPercentage(to: percent)
        self.status = self.getStatus()
    }

    public func getStatusString(atDate: Date = Date()) -> String {
        return getStatus(atDate: atDate).rawValue
    }

    public func getDuration(for status: PomoStatus) -> Double {
        switch status {
        case .work:
            return workDuration
        case .rest:
            return restDuration
        case .longBreak:
            return breakDuration
        case .end:
            return 0.0
        }
    }

    public func currentPomo(atDate date: Date = Date()) -> Int {
        return min((getIndex(atDate: date))/2 + 1, pomoCount)
    }

    public func incrementPomos() {
        pomoCount += 1
        if pomoCount > maxPomos { pomoCount = maxPomos }
        reset(pomos: pomoCount,
              work: workDuration,
              rest: restDuration,
              longBreak: breakDuration)
    }

    public func decrementPomos() {
        pomoCount -= 1
        if pomoCount < 1 { pomoCount = 1 }
        reset(pomos: pomoCount,
              work: workDuration,
              rest: restDuration,
              longBreak: breakDuration)
    }

    func toggleAndRecord() {
        if !isPaused {
            recordTimes()
        }
        super.toggle()
    }

    func recordTimes() {
        let indexAtUnpause = getIndex(atDate: unpauseTime)
        let indexAtPause = getIndex(atDate: Date.now)
        guard indexAtUnpause <= indexAtPause &&
                indexAtPause < order.count &&
                indexAtUnpause < order.count else { return }

        let now = Date.now
        var startOfHour = Calendar.current.startOfHour(for: unpauseTime)
        var hourAccumulator = unpauseTime.timeIntervalSince(startOfHour)

        var workTime = 0.0
        var restTime = 0.0
        var breakTime = 0.0
        for i in indexAtUnpause...indexAtPause {
            var timeToAdd = order[i].timeInterval
            if indexAtUnpause == indexAtPause {
                timeToAdd = now.timeIntervalSince(unpauseTime)
            } else if i == indexAtUnpause {
                timeToAdd = timeRemaining(atDate: unpauseTime)
            } else if i == indexAtPause {
                timeToAdd -= timeRemaining(atDate: now)
            }

            addToRecordingTimes(timeToAdd, for: order[i].status, &workTime, &restTime, &breakTime)

            hourAccumulator += timeToAdd
            while hourAccumulator > 60 * 60 {
                let excess = hourAccumulator.truncatingRemainder(dividingBy: 60 * 60)
                addToRecordingTimes(-excess, for: order[i].status, &workTime, &restTime, &breakTime)

                recordTime(workTime: workTime, restTime: restTime, breakTime: breakTime, for: startOfHour)

                workTime = 0.0; restTime = 0.0; breakTime = 0.0
                addToRecordingTimes(excess, for: order[i].status, &workTime, &restTime, &breakTime)

                startOfHour.addTimeInterval(60 * 60)
                hourAccumulator -= 60 * 60
            }
        }
        recordTime(workTime: workTime, restTime: restTime, breakTime: breakTime, for: startOfHour)
    }

    private func recordTime(workTime: Double, restTime: Double, breakTime: Double, for date: Date) {
        if let context {
            Logger().log("Recording cumulative time adding: work=\(workTime.rounded()) rest=\(restTime.rounded()) break=\(breakTime.rounded()) for=\(date.formatted())")
            CumulativeTimeData.addTime(work: workTime, rest: restTime, longBreak: breakTime,
                                       date: date, context: context)
        }
    }

    private func addToRecordingTimes(_ value: Double, for status: PomoStatus, _ workTime: inout Double, _ restTime: inout Double, _ breakTime: inout Double) {
        switch status {
        case .work:
            workTime += value
        case .rest:
            restTime += value
        case .longBreak:
            breakTime += value
        case .end:
            break
        }
    }

    public func reset(pomos: Int, work: Double, rest: Double, longBreak: Double) {
        pomoCount = pomos
        workDuration = work
        restDuration = rest
        breakDuration = longBreak
        let pomoTimes = getPomoTimes(pomos, work, rest, longBreak)
        let timeIntervals = pomoTimes.map { $0.timeInterval }
        order = pomoTimes
        status = pomoTimes.first?.status ?? .work

        super.reset(timeIntervals) { [weak self] index in
            if index < pomoTimes.count {
                self?.status = pomoTimes[index].status
                self?.pomoAction(pomoTimes[index].status)
            } else {
                self?.status = .end
                self?.pomoAction(.end)
                withAnimation {
                    self?.toggleAndRecord()
                }
            }
        }
    }

    public func reset() {
        super.reset([])
        status = getStatus()
    }

    public func sync(with otherTimer: PomoTimer) {
        order = otherTimer.order
        pomoCount = otherTimer.pomoCount
        workDuration = otherTimer.workDuration
        restDuration = otherTimer.restDuration
        breakDuration = otherTimer.breakDuration
        super.sync(with: otherTimer)
    }

    override func saveToUserDefaults() {
        if let encoded = try? PropertyListEncoder().encode(order) {
            UserDefaults.pomo?.set(encoded, forKey: "order")
        }
        UserDefaults.pomo?.set(pomoCount, forKey: "pomoCount")
        UserDefaults.pomo?.set(workDuration, forKey: "pomoWorkDuration")
        UserDefaults.pomo?.set(restDuration, forKey: "pomoRestDuration")
        UserDefaults.pomo?.set(breakDuration, forKey: "pomoBreakDuration")
        super.saveToUserDefaults()
    }

    override func restoreFromUserDefaults() {
        if let data = UserDefaults.pomo?.object(forKey: "order") as? Data {
            if let orderDecoded = try? PropertyListDecoder().decode([PomoTime].self, from: data) {
                order = orderDecoded
            }
        }
        pomoCount = UserDefaults.pomo?.object(forKey: "pomoCount") as? Int ?? pomoCount
        workDuration = UserDefaults.pomo?.object(forKey: "pomoWorkDuration") as? Double ?? workDuration
        restDuration = UserDefaults.pomo?.object(forKey: "pomoRestDuration") as? Double ?? restDuration
        breakDuration = UserDefaults.pomo?.object(forKey: "pomoBreakDuration") as? Double ?? breakDuration
        Logger().log("RESTORE::order=\(self.order.map { $0.statusString })  pomoCount=\(self.pomoCount)  workDuration=\(self.workDuration.rounded())  restDuration=\(self.restDuration.rounded())  breakDuration=\(self.breakDuration.rounded())")
        super.restoreFromUserDefaults()
        status = getStatus()
    }

    // Note that the action closure in not encoded/decoded
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pomoCount = try values.decode(Int.self, forKey: .pomoCount)
        status = .work
        workDuration = try values.decode(Double.self, forKey: .work)
        restDuration = try values.decode(Double.self, forKey: .rest)
        breakDuration = try values.decode(Double.self, forKey: .longBreak)
        let pomoTimes = try values.decode([PomoTime].self, forKey: .order)
        order = pomoTimes
        pomoAction = { _ in }
        try super.init(from: decoder)
        status = getStatus()
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(order, forKey: .order)
        try container.encode(pomoCount, forKey: .pomoCount)
        try container.encode(workDuration, forKey: .work)
        try container.encode(restDuration, forKey: .rest)
        try container.encode(breakDuration, forKey: .longBreak)
        try super.encode(to: encoder)
    }

    enum CodingKeys: String, CodingKey {
        case order
        case pomoCount
        case work
        case rest
        case longBreak
        case action
    }
}

private func getPomoTimes(_ pomos: Int, _ work: Double, _ rest: Double, _ longBreak: Double) -> [PomoTime] {
    var pomoTimes: [PomoTime] = []
    addPomos(pomos, work, rest, &pomoTimes)
    addLongBreak(longBreak, &pomoTimes)
    return pomoTimes
}

private func addPomos(_ pomos: Int, _ work: Double, _ rest: Double, _ pomoTimes: inout [PomoTime]) {
    for _ in 0..<pomos {
        pomoTimes.append(PomoTime(work, .work))
        pomoTimes.append(PomoTime(rest, .rest))
    }
}

private func addLongBreak(_ longBreak: Double, _ pomoTimes: inout [PomoTime]) {
    pomoTimes.append(PomoTime(longBreak, .longBreak))
}
