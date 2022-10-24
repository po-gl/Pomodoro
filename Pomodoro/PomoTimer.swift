//
//  PomoTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI


class PomoTimer: SequenceTimer {
    @Published var order: [PomoTime]
    var status: PomoStatus { get { return order[currentIndex].getStatus() } }
    var statusString: String { get { return order[currentIndex].getStatusString() } }
    
    var pomoCount: Int
    var longBreakTime: Double
    
    private let maxPomos: Int = 6
    
//    static let defaultWorkTime: Double = 25.0 * 60.0
//    static let defaultRestTime: Double = 5.0 * 60.0
//    static let defaultBreakTime: Double = 30.0 * 60.0
    
    static let defaultWorkTime: Double = 4.0
    static let defaultRestTime: Double = 2.0
    static let defaultBreakTime: Double = 6.0
    
    init(pomos: Int, longBreak: Double) {
        pomoCount = pomos
        longBreakTime = longBreak
        let pomoTimes = getPomoTimes(pomos, longBreak)
        let timeIntervals = pomoTimes.map { $0.getTime() }
        order = pomoTimes
        super.init(sequenceOfIntervals: timeIntervals)
    }
    
    func incrementPomos() {
        pomoCount += 1
        if pomoCount > maxPomos { pomoCount = maxPomos }
        reset(pomos: pomoCount, longBreak: longBreakTime)
    }
    
    func decrementPomos() {
        pomoCount -= 1
        if pomoCount < 1 { pomoCount = 1 }
        reset(pomos: pomoCount, longBreak: longBreakTime)
    }
    
    func reset(pomos: Int, longBreak: Double) {
        pomoCount = pomos
        longBreakTime = longBreak
        let pomoTimes = getPomoTimes(pomos, longBreak)
        let timeIntervals = pomoTimes.map { $0.getTime() }
        order = pomoTimes
        super.reset(timeIntervals)
    }
    
    override func reset(_ sequenceOfIntervals: [TimeInterval] = []) {
        super.reset([])
    }
    
    override func start(_ sequenceOfIntervals: [TimeInterval]) {
        super.start(self.sequenceOfIntervals)
    }
    
    override func saveToUserDefaults() {
        UserDefaults.standard.set(order, forKey: "order")
        super.saveToUserDefaults()
    }
    
    override func restoreFromUserDefaults() {
        order = UserDefaults.standard.object(forKey: "order") as? [PomoTime] ?? order
        super.restoreFromUserDefaults()
    }
}


fileprivate func getPomoTimes(_ pomos: Int, _ longBreak: Double) -> [PomoTime] {
    var pomoTimes: [PomoTime] = []
    addPomos(pomos, &pomoTimes)
    addLongBreak(longBreak, &pomoTimes)
    return pomoTimes
}


fileprivate func addPomos(_ pomos: Int, _ pomoTimes: inout [PomoTime]) {
    for _ in 0..<pomos {
        pomoTimes.append(PomoTime(PomoTimer.defaultWorkTime, .work))
        pomoTimes.append(PomoTime(PomoTimer.defaultRestTime, .rest))
    }
}

fileprivate func addLongBreak(_ longBreak: Double, _ pomoTimes: inout [PomoTime]) {
    pomoTimes.append(PomoTime(longBreak, .longBreak))
}
