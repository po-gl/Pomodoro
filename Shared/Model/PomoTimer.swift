//
//  PomoTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI
import OSLog

class PomoTimer: SequenceTimer {
    @Published var order: [PomoTime]
    @Published var pomoCount: Int

    var workDuration: Double
    var restDuration: Double
    var breakDuration: Double

    private let maxPomos: Int = 6

    static let defaultWorkTime: Double = 25.0 * 60.0
    static let defaultRestTime: Double = 5.0 * 60.0
    static let defaultBreakTime: Double = 30.0 * 60.0

    private var pomoAction: (PomoStatus) -> Void

    init(pomos: Int = 4,
         work: Double = defaultWorkTime,
         rest: Double = defaultRestTime,
         longBreak: Double = defaultBreakTime,
         perform action: @escaping (PomoStatus) -> Void = { _ in return },
         timeProvider: Timer.Type = Timer.self) {
        pomoCount = pomos
        workDuration = work
        restDuration = rest
        breakDuration = longBreak
        pomoAction = action
        let pomoTimes = getPomoTimes(pomos, work, rest, longBreak)
        let timeIntervals = pomoTimes.map { $0.getTime() }
        order = pomoTimes

        weak var selfInstance: PomoTimer?
        super.init(timeIntervals, perform: { index in
            if index < pomoTimes.count {
                action(pomoTimes[index].getStatus())
            } else {
                selfInstance?.toggle()
                action(.end)
            }
        }, timerProvider: timeProvider)
        selfInstance = self
    }

    public func getStatus(atDate: Date = Date()) -> PomoStatus {
        let index = getIndex(atDate: atDate)
        if index == order.count-1 && timeRemaining(atDate: atDate) == 0.0 {
            return .end
        }
        return order[index].getStatus()
    }

    public func getProgress(atDate: Date = Date()) -> Double {
        let index = getIndex(atDate: atDate)
        let intervals = order.map { $0.getTime() }
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
    }

    public func getStatusString(atDate: Date = Date()) -> String {
        return getStatus(atDate: atDate).rawValue
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

    public func reset(pomos: Int, work: Double, rest: Double, longBreak: Double) {
        pomoCount = pomos
        workDuration = work
        restDuration = rest
        breakDuration = longBreak
        let pomoTimes = getPomoTimes(pomos, work, rest, longBreak)
        let timeIntervals = pomoTimes.map { $0.getTime() }
        order = pomoTimes

        super.reset(timeIntervals) { index in
            if index < pomoTimes.count {
                self.pomoAction(pomoTimes[index].getStatus())
            } else {
                self.toggle()
                self.pomoAction(.end)
            }
        }
    }

    public func reset() {
        super.reset([])
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
        Logger().log("RESTORE::order=\(self.order.map { $0.getStatusString() })  pomoCount=\(self.pomoCount)  workDuration=\(self.workDuration.rounded())  restDuration=\(self.restDuration.rounded())  breakDuration=\(self.breakDuration.rounded())")
        super.restoreFromUserDefaults()
    }

    // Note that the action closure in not encoded/decoded
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pomoCount = try values.decode(Int.self, forKey: .pomoCount)
        workDuration = try values.decode(Double.self, forKey: .work)
        restDuration = try values.decode(Double.self, forKey: .rest)
        breakDuration = try values.decode(Double.self, forKey: .longBreak)
        let pomoTimes = try values.decode([PomoTime].self, forKey: .order)
        order = pomoTimes
        pomoAction = { _ in }
        try super.init(from: decoder)
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
