//
//  SequenceTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation
import SwiftUI

class SequenceTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0.0
    @Published var isPaused: Bool = true
    
    public var sequenceOfIntervals: [TimeInterval] = []
    @Published var currentIndex: Int = 0
    
    private var nextIndex: Int {
        return currentIndex + 1
    }
    
    private let intervalInSeconds = 1.0
    
    private var timerProvider: Timer.Type
    private var timer = Timer()
    
    
    init(sequenceOfIntervals: [TimeInterval], timerProvider: Timer.Type = Timer.self) {
        self.timerProvider = timerProvider
        self.sequenceOfIntervals = sequenceOfIntervals
        if !sequenceOfIntervals.isEmpty {
            start(self.sequenceOfIntervals)
        }
    }
    
    public func start(_ sequenceOfIntervals: [TimeInterval]) {
        self.sequenceOfIntervals = sequenceOfIntervals
        reset()
        unpause()
    }
    
    public func reset(_ sequenceOfIntervals: [TimeInterval] = []) {
        if !sequenceOfIntervals.isEmpty {
            self.sequenceOfIntervals = sequenceOfIntervals
        }
        end()
        currentIndex = 0
        updateTimeRemaining(0)
        createTimer()
    }
    
    public func saveToUserDefaults() {
        let timeSinceAppSuspended = Date()
        UserDefaults.standard.set(isPaused, forKey: "isPaused")
        UserDefaults.standard.set(timeSinceAppSuspended, forKey: "timeSinceAppSuspended")
        UserDefaults.standard.set(timeRemaining, forKey: "timeRemaining")
        UserDefaults.standard.set(currentIndex, forKey: "currentIndex")
        UserDefaults.standard.set(sequenceOfIntervals, forKey: "sequenceOfIntervals")
    }
    
    public func restoreFromUserDefaults() {
        isPaused = UserDefaults.standard.bool(forKey: "isPaused")
        if isPaused {
            timeRemaining = UserDefaults.standard.object(forKey: "timeRemaining") as! TimeInterval
        } else {
            let timeSinceAppSuspended = UserDefaults.standard.object(forKey: "timeSinceAppSuspended") as? Date ?? Date()
            let now = Date()
            let secondsSinceAppSuspended = now.distance(to: timeSinceAppSuspended)
            let timeRemainingAtAppSuspended = UserDefaults.standard.object(forKey: "timeRemaining") as? TimeInterval ?? timeRemaining
            timeRemaining = timeRemainingAtAppSuspended - secondsSinceAppSuspended
        }
        currentIndex = UserDefaults.standard.integer(forKey: "currentIndex")
        sequenceOfIntervals = UserDefaults.standard.object(forKey: "sequenceOfIntervals") as? [TimeInterval] ?? sequenceOfIntervals
        updateTimeRemaining(currentIndex)
    }
    
    private func createTimer() {
        self.timer = timerProvider.scheduledTimer(withTimeInterval: intervalInSeconds, repeats: true) {_ in
            self.timerBlock()
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func timerBlock() {
        if notPaused() {
            decreaseTimeRemaining()
        }
    }
    
    private func notPaused() -> Bool {
        return !isPaused
    }
    
    private func decreaseTimeRemaining() {
        if timeRemaining > 0.0 {
            timeRemaining -= 1.0
        } else {
            updateToNextInterval()
        }
    }
    
    private func updateToNextInterval() {
        currentIndex = getNextIntervalIndex()
        updateTimeRemaining(currentIndex)
    }
    
    private func getNextIntervalIndex() -> Int {
        return nextIndex % sequenceOfIntervals.count
    }
    
    private func updateTimeRemaining(_ index: Int) {
        timeRemaining = sequenceOfIntervals[index]
    }
    
    func pause() {
        isPaused = true
    }
    
    func unpause() {
        isPaused = false
    }
    
    func toggle() {
        isPaused.toggle()
    }
    
    func end() {
        timer.invalidate()
        pause()
    }
}

