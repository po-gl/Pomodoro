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
    
    private var sequenceOfIntervals: [TimeInterval] = []
    @Published var currentIndex: Int = 0
    
    private var nextIndex: Int {
        return currentIndex + 1
    }
    
    private let intervalInSeconds = 1.0
    
    private var timerProvider: Timer.Type
    private var timer = Timer()
    
    
    init(sequenceOfIntervals: [TimeInterval], timerProvider: Timer.Type = Timer.self) {
        self.timerProvider = timerProvider
        if !sequenceOfIntervals.isEmpty {
            start(sequenceOfIntervals)
        }
    }
    
    func start(_ sequenceOfIntervals: [TimeInterval]) {
        self.sequenceOfIntervals = sequenceOfIntervals
        reset()
        unpause()
    }
    
    func reset(_ sequenceOfIntervals: [TimeInterval] = []) {
        if !sequenceOfIntervals.isEmpty {
            self.sequenceOfIntervals = sequenceOfIntervals
        }
        end()
        currentIndex = 0
        timeRemaining = self.sequenceOfIntervals[0]
        createTimer()
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

