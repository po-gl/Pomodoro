//
//  PomoTimer.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation
import SwiftUI


class PomoTimer: SequenceTimer, Codable {
    @Published var order: [PomoTime]
    @Published var pomoCount: Int
    
    private var longBreakTime: Double
    
    private let maxPomos: Int = 6
         
//    static let defaultWorkTime: Double = 4.0
//    static let defaultRestTime: Double = 2.0
//    static let defaultBreakTime: Double = 6.0
    static let defaultWorkTime: Double = 25.0 * 60.0
    static let defaultRestTime: Double = 5.0 * 60.0
    static let defaultBreakTime: Double = 30.0 * 60.0
    
    private var pomoAction: (PomoStatus) -> Void
    
    init(pomos: Int = 4, longBreak: Double = defaultBreakTime, perform action: @escaping (PomoStatus) -> Void = { _ in return }, timeProvider: Timer.Type = Timer.self) {
        pomoCount = pomos
        longBreakTime = longBreak
        pomoAction = action
        let pomoTimes = getPomoTimes(pomos, longBreak)
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
    
    public func getStatusString(atDate: Date = Date()) -> String {
        return getStatus(atDate: atDate).rawValue
    }
    
    public func currentPomo(atDate date: Date = Date()) -> Int {
        return min((getIndex(atDate: date)+1)/2 + 1, pomoCount)
    }
    
    
    public func incrementPomos() {
        pomoCount += 1
        if pomoCount > maxPomos { pomoCount = maxPomos }
        reset(pomos: pomoCount, longBreak: longBreakTime)
    }
    
    public func decrementPomos() {
        pomoCount -= 1
        if pomoCount < 1 { pomoCount = 1 }
        reset(pomos: pomoCount, longBreak: longBreakTime)
    }
    
    public func reset(pomos: Int, longBreak: Double) {
        pomoCount = pomos
        longBreakTime = longBreak
        let pomoTimes = getPomoTimes(pomos, longBreak)
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
    
    override func saveToUserDefaults() {
        if let encoded = try? PropertyListEncoder().encode(order) {
            UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(encoded, forKey: "order")
        }
        UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.set(pomoCount, forKey: "pomoCount")
        super.saveToUserDefaults()
    }
    
    override func restoreFromUserDefaults() {
        if let data = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "order") as? Data {
            if let orderDecoded = try? PropertyListDecoder().decode([PomoTime].self, from: data) {
                order = orderDecoded
            }
        }
        pomoCount = UserDefaults(suiteName: "group.com.po-gl.pomodoro")!.object(forKey: "pomoCount") as? Int ?? pomoCount
        print("RESTORE::order=\(order.map { $0.getStatusString() })  pomoCount=\(pomoCount)")
        super.restoreFromUserDefaults()
    }
    
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pomoCount = try values.decode(Int.self, forKey: .pomoCount)
        longBreakTime = try values.decode(Double.self, forKey: .longBreak)
        let pomoTimes = try values.decode([PomoTime].self, forKey: .order)
        order = pomoTimes
        pomoAction = { _ in }
        super.init(pomoTimes.map { $0.getTime() }, perform: { _ in })
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(order, forKey: .order)
        try container.encode(pomoCount, forKey: .pomoCount)
        try container.encode(longBreakTime, forKey: .longBreak)
    }
    
    enum CodingKeys: String, CodingKey {
        case order
        case pomoCount
        case longBreak
        case action
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
