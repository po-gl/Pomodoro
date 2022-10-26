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
        
        let diff = ((timeAmounts[index] + startDelay(index)) - (sinceStartOffset - startOffset - pauseOffset)).rounded()
        
        return diff > 0.0 ? diff : 0.0
    }
    
    
    public func getIndex(atDate: Date = Date()) -> Int {
        let now = atDate
        let sinceStartOffset = now.timeIntervalSince(startTime)
        let pauseOffset = (isPaused ? now.timeIntervalSince(pauseStart) : 0.0) + pauseOffset
        
        var runningAmount = 0.0
        for (index, amount) in timeAmounts.enumerated() {
            let diff = ((amount + startDelay(index)) - (sinceStartOffset - runningAmount - pauseOffset)).rounded()
            if diff >= 0.0 {
                return index
            }
            runningAmount += amount
        }
        return timeAmounts.count-1
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
        UserDefaults.standard.set(Date(), forKey: "timeSinceAppSuspended")
        
        UserDefaults.standard.set(isPaused, forKey: "isPaused")
        UserDefaults.standard.set(startTime, forKey: "startTime")
        UserDefaults.standard.set(timeAmounts, forKey: "timeAmounts")
        UserDefaults.standard.set(pauseStart, forKey: "pauseStart")
        UserDefaults.standard.set(pauseOffset, forKey: "pauseOffset")
        timer.invalidate()
    }
    
    public func restoreFromUserDefaults() {
        isPaused = UserDefaults.standard.object(forKey: "isPaused") as? Bool ?? isPaused
        startTime = UserDefaults.standard.object(forKey: "startTime") as? Date ?? startTime
        timeAmounts = UserDefaults.standard.object(forKey: "timeAmounts") as? [TimeInterval] ?? timeAmounts
        pauseStart = UserDefaults.standard.object(forKey: "pauseStart") as? Date ?? pauseStart
        pauseOffset = UserDefaults.standard.object(forKey: "pauseOffset") as? TimeInterval ?? pauseOffset
        print("RESTORE::isPaused=\(isPaused)   startTime=\(startTime)   pauseStart=\(pauseStart)   pauseOffset=\(pauseOffset)   timeAmounts=\(timeAmounts)")
        
        if !isPaused {
            createTimer(index: getIndex())
        } else {
            timer.invalidate()
        }
    }
}

