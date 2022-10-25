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
    
    var pomoCount: Int
    var longBreakTime: Double
    
    private let maxPomos: Int = 6
    
    static let defaultWorkTime: Double = 25.0 * 60.0
    static let defaultRestTime: Double = 5.0 * 60.0
    static let defaultBreakTime: Double = 30.0 * 60.0
    
    init(pomos: Int, longBreak: Double) {
        pomoCount = pomos
        longBreakTime = longBreak
        let pomoTimes = getPomoTimes(pomos, longBreak)
        let timeIntervals = pomoTimes.map { $0.getTime() }
        order = pomoTimes
        super.init(timeIntervals)
    }
    
    
    public func getStatus(atDate: Date = Date()) -> PomoStatus {
        let index = getIndex(atDate: atDate)
        return order[index].getStatus()
    }
    
    public func getStatusString(atDate: Date = Date()) -> String {
        let index = getIndex(atDate: atDate)
        return order[index].getStatusString()
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
        super.start()
    }
    
    override func saveToUserDefaults() {
        if let encoded = try? PropertyListEncoder().encode(order) {
            UserDefaults.standard.set(encoded, forKey: "order")
        }
        super.saveToUserDefaults()
    }
    
    override func restoreFromUserDefaults() {
        if let data = UserDefaults.standard.object(forKey: "order") as? Data {
            if let orderDecoded = try? PropertyListDecoder().decode([PomoTime].self, from: data) {
                order = orderDecoded
                print("RESTORE::order=\(order.map { $0.getStatusString() })")
            }
        }
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
