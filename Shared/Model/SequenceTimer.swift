//
//  SequenceTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation
import SwiftUI
import OSLog

class SequenceTimer: ObservableObject, Codable {
    @Published var isPaused: Bool = true
    @Published var isReset: Bool = false

    private var startTime = Date()
    private var timeAmounts: [TimeInterval] = []

    private var pauseStart = Date()
    private var pauseOffset: TimeInterval = 0.0

    private var scrubOffset: TimeInterval = 0.0

    public private(set) var action: (Int) -> Void
    private var timer = Timer()
    private var timerProvider = Timer.self

    init(_ sequenceOfIntervals: [TimeInterval],
         perform: @escaping (Int) -> Void,
         timerProvider: Timer.Type = Timer.self) {
        timeAmounts = sequenceOfIntervals
        action = perform
        self.timerProvider = timerProvider
        if !sequenceOfIntervals.isEmpty {
            start(sequenceOfIntervals)
        }
    }

    public func timeRemaining(atDate now: Date = Date()) -> TimeInterval {
        let index = getIndex(atDate: now)
        return timeRemaining(for: index, atDate: now)
    }

    public func timeRemaining(for index: Int, atDate now: Date = Date()) -> TimeInterval {
        let sinceStartOffset = now.timeIntervalSince(startTime)
        let pauseOffset = (isPaused ? now.timeIntervalSince(pauseStart) : 0.0) + pauseOffset
        let startOffset = timeAmounts[0..<index].reduce(0.0, +)

        let diff = calculateDiff(timeAmounts[index],
                                 delay: startDelay(index),
                                 offset: sinceStartOffset - startOffset - pauseOffset - scrubOffset)

        return diff > 0.0 ? diff : 0.0
    }

    public func getIndex(atDate: Date = Date()) -> Int {
        let now = atDate
        let sinceStartOffset = now.timeIntervalSince(startTime)
        let pauseOffset = (isPaused ? now.timeIntervalSince(pauseStart) : 0.0) + pauseOffset

        var runningAmount = 0.0
        for (index, amount) in timeAmounts.enumerated() {
            let diff = calculateDiff(amount,
                                     delay: startDelay(index),
                                     offset: sinceStartOffset - runningAmount - pauseOffset - scrubOffset)
            if diff >= 0.0 {
                return index
            }
            runningAmount += amount
        }
        return timeAmounts.count-1
    }

    private func calculateDiff(_ timeAmount: Double, delay startDelay: Double, offset: Double) -> Double {
        return ((timeAmount + startDelay) - offset).rounded()
    }

    public func setPercentage(to percent: Double) {
        let safePercent = min(max(percent, 0.0), 1.0)
        reset()
        scrubOffset = -totalTime(at: safePercent)
    }

    public func getCurrentPercentage(atDate: Date = Date()) -> Double {
        let timeSoFar = totalTimeSoFar(atDate: atDate)
        let total = timeAmounts.reduce(0, +)
        let progress = timeSoFar / total
        return progress <= 1.0 ? progress : 1.0
    }

    private func totalTimeSoFar(atDate: Date = Date()) -> TimeInterval {
        let index = getIndex(atDate: atDate)
        var cumulative = 0.0
        for i in 0..<index {
           cumulative += timeAmounts[i]
        }
        let currentTime = timeAmounts[index] - floor(timeRemaining(atDate: atDate))
        return cumulative + currentTime
    }

    private func totalTime(at percent: Double, atDate: Date = Date()) -> TimeInterval {
        let total = timeAmounts.reduce(0, +)
        var cumulative = 0.0, i = 0
        while cumulative < total {
            cumulative += timeAmounts[i]
            if cumulative / total >= percent { break }
            i += 1
        }
        cumulative = min(max(cumulative, 0.0), total + Double(timeAmounts.count-1))
        cumulative += Double(i)
        // remove extra
        while cumulative / total > percent {
            cumulative -= 1.0 * 60.0
        }
        return cumulative
    }

    public func start(_ sequenceOfIntervals: [TimeInterval] = []) {
        if !sequenceOfIntervals.isEmpty {
            timeAmounts = sequenceOfIntervals
        }
        reset()
        unpause()
    }

    public func reset(_ sequenceOfIntervals: [TimeInterval] = []) {
        if !sequenceOfIntervals.isEmpty {
            timeAmounts = sequenceOfIntervals
        }
        isReset = true
        pause()
        pauseOffset = 0.0
        scrubOffset = 0.0
        pauseStart = Date()
        startTime = Date()
    }

    public func reset(_ sequenceOfIntervals: [TimeInterval] = [], perform: @escaping (Int) -> Void) {
        action = perform
        reset(sequenceOfIntervals)
    }

    public func sync(with otherTimer: SequenceTimer) {
        startTime = otherTimer.startTime
        timeAmounts = otherTimer.timeAmounts
        pauseStart = otherTimer.pauseStart
        pauseOffset = otherTimer.pauseOffset
        scrubOffset = otherTimer.scrubOffset

        pause()
        if !otherTimer.isPaused {
            unpause()
        }
    }

    public func pause() {
        isPaused = true
        pauseStart = Date()
        timer.invalidate()
    }

    public func unpause() {
        isPaused = false
        isReset = false
        pauseOffset += Date().timeIntervalSince(pauseStart)
        createTimer(index: getIndex())
    }

    public func toggle() {
        if isPaused {
            unpause()
        } else {
            pause()
        }
    }

    private func startDelay(_ index: Int) -> Double {
        return 1.0 * Double(index)
    }

    private func createTimer(index: Int) {
        self.timer = timerProvider.scheduledTimer(withTimeInterval: self.timeRemaining(for: index),
                                                  repeats: false) { _ in
            self.action(index+1)
            if index < self.timeAmounts.count-1 {
                self.createTimer(index: index+1)
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }

    public func saveToUserDefaults() {
        UserDefaults.pomo?.set(Date(), forKey: "timeSinceAppSuspended")

        UserDefaults.pomo?.set(isPaused, forKey: "isPaused")
        UserDefaults.pomo?.set(isReset, forKey: "isReset")
        UserDefaults.pomo?.set(startTime, forKey: "startTime")
        UserDefaults.pomo?.set(timeAmounts, forKey: "timeAmounts")
        UserDefaults.pomo?.set(pauseStart, forKey: "pauseStart")
        UserDefaults.pomo?.set(pauseOffset, forKey: "pauseOffset")
        UserDefaults.pomo?.set(scrubOffset, forKey: "scrubOffset")
        timer.invalidate()
    }

    public func restoreFromUserDefaults() {
        isPaused = UserDefaults.pomo?.object(forKey: "isPaused") as? Bool ?? isPaused
        isReset = UserDefaults.pomo?.object(forKey: "isReset") as? Bool ?? isReset
        startTime = UserDefaults.pomo?.object(forKey: "startTime") as? Date ?? startTime
        timeAmounts = UserDefaults.pomo?.object(forKey: "timeAmounts") as? [TimeInterval] ?? timeAmounts
        pauseStart = UserDefaults.pomo?.object(forKey: "pauseStart") as? Date ?? pauseStart
        pauseOffset = UserDefaults.pomo?.object(forKey: "pauseOffset") as? TimeInterval ?? pauseOffset
        scrubOffset = UserDefaults.pomo?.object(forKey: "scrubOffset") as? TimeInterval ?? scrubOffset
        Logger().log("""
              RESTORE::isPaused=\(self.isPaused)   startTime=\(self.startTime)   pauseStart=\(self.pauseStart) \
              pauseOffset=\(self.pauseOffset)   timeAmounts=\(self.timeAmounts)
              """)

        if !isPaused {
            createTimer(index: getIndex())
        } else {
            timer.invalidate()
        }
    }

    // Note that action closure is not encoded/decoded
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isPaused = try values.decode(Bool.self, forKey: .isPaused)
        isReset = try values.decode(Bool.self, forKey: .isReset)
        startTime = try values.decode(Date.self, forKey: .startTime)
        timeAmounts = try values.decode([TimeInterval].self, forKey: .timeAmounts)
        pauseStart = try values.decode(Date.self, forKey: .pauseStart)
        pauseOffset = try values.decode(TimeInterval.self, forKey: .pauseOffset)
        scrubOffset = try values.decode(TimeInterval.self, forKey: .scrubOffset)
        action = { _ in }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isPaused, forKey: .isPaused)
        try container.encode(isReset, forKey: .isReset)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(timeAmounts, forKey: .timeAmounts)
        try container.encode(pauseStart, forKey: .pauseStart)
        try container.encode(pauseOffset, forKey: .pauseOffset)
        try container.encode(scrubOffset, forKey: .scrubOffset)
    }

    enum CodingKeys: String, CodingKey {
        case isPaused
        case isReset
        case startTime
        case timeAmounts
        case pauseStart
        case pauseOffset
        case scrubOffset
    }
}
