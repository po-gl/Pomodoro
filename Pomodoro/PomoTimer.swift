//
//  PomoTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI


class PomoTimer: SequenceTimer {
    var order: [PomoTime]
    var status: PomoStatus { get { return order[currentIndex].getStatus() } }
    var statusString: String { get { return order[currentIndex].getStatusString() } }
    
    init(pomos: Int, longBreak: Double) {
        var pomoTimes: [PomoTime] = []
        addPomos(pomos, &pomoTimes)
        addLongBreak(longBreak, &pomoTimes)
        order = pomoTimes
        
        let timeIntervals = pomoTimes.map { $0.getTime() }
        super.init(sequenceOfIntervals: timeIntervals)
    }
    
    override func start(_ sequenceOfIntervals: [TimeInterval]) {
        super.start(self.sequenceOfIntervals)
    }
    
    override func reset(_ sequenceOfIntervals: [TimeInterval] = []) {
        super.reset([])
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


fileprivate func addPomos(_ pomos: Int, _ pomoTimes: inout [PomoTime]) {
    for _ in 0..<pomos {
//        pomoTimes.append(PomoTime(25 * 60.0, .work))
//        pomoTimes.append(PomoTime(5 * 60.0, .rest))
        pomoTimes.append(PomoTime(4.0, .work))
        pomoTimes.append(PomoTime(2.0, .rest))
    }
}

fileprivate func addLongBreak(_ longBreak: Double, _ pomoTimes: inout [PomoTime]) {
//    pomoTimes.append(PomoTime(longBreak * 60.0, .longBreak))
    pomoTimes.append(PomoTime(5.0, .longBreak))
}
