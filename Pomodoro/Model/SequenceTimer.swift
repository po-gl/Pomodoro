//
//  SequenceTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation
import SwiftUI

class SequenceTimer: ObservableObject {
    @Published var isPaused: Bool = true
    
    private var startTime = Date()
    private var timeAmounts: [TimeInterval] = []
    
    private var pauseStart = Date()
    private var pauseOffset: TimeInterval = 0.0
    
    private var scrubOffset: TimeInterval = 0.0
    
    public private(set) var action: (Int) -> Void
    private var timer = Timer()
    private var timerProvider = Timer.self
    
    
    init(_ sequenceOfIntervals: [TimeInterval], perform: @escaping (Int) -> Void, timerProvider: Timer.Type = Timer.self) {
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
            cumulative += timeAmounts[i] + startDelay(i)
            if cumulative / total >= percent { break }
            i += 1
        }
        cumulative = min(max(cumulative, 0.0), total + Double(timeAmounts.count-1))
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
        pause()
        pauseOffset = 0.0
        pauseStart = Date()
        startTime = Date()
    }
    
    public func reset(_ sequenceOfIntervals: [TimeInterval] = [], perform: @escaping (Int) -> Void) {
        action = perform
        reset(sequenceOfIntervals)
    }
    
    
    public func pause() {
        isPaused = true
        pauseStart = Date()
        timer.invalidate()
    }
    
    public func unpause() {
        isPaused = false
        pauseOffset += Date().timeIntervalSince(pauseStart)
        createTimer(index: getIndex())
    }
    
    public func toggle() {
        isPaused ? unpause() : pause()
    }
    
    
    private func startDelay(_ index: Int) -> Double {
        return 1.0 * Double(index)
    }
    
    
    private func createTimer(index: Int) {
        self.timer = timerProvider.scheduledTimer(withTimeInterval: self.timeRemaining(for: index), repeats: false) { _ in
            self.action(index+1)
            if index < self.timeAmounts.count-1 {
                self.createTimer(index: index+1)
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    
    public func saveToUserDefaults() {
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(Date(), forKey: "timeSinceAppSuspended")
        
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(isPaused, forKey: "isPaused")
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(startTime, forKey: "startTime")
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(timeAmounts, forKey: "timeAmounts")
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(pauseStart, forKey: "pauseStart")
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(pauseOffset, forKey: "pauseOffset")
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(scrubOffset, forKey: "scrubOffset")
        timer.invalidate()
    }
    
    public func restoreFromUserDefaults() {
        isPaused = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "isPaused") as? Bool ?? isPaused
        startTime = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "startTime") as? Date ?? startTime
        timeAmounts = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "timeAmounts") as? [TimeInterval] ?? timeAmounts
        pauseStart = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "pauseStart") as? Date ?? pauseStart
        pauseOffset = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "pauseOffset") as? TimeInterval ?? pauseOffset
        scrubOffset = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "scrubOffset") as? TimeInterval ?? scrubOffset
        print("RESTORE::isPaused=\(isPaused)   startTime=\(startTime)   pauseStart=\(pauseStart)   pauseOffset=\(pauseOffset)   timeAmounts=\(timeAmounts)")
        
        if !isPaused {
            createTimer(index: getIndex())
        } else {
            timer.invalidate()
        }
    }
}

