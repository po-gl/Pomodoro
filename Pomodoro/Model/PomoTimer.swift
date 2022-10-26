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
         
    static let defaultWorkTime: Double = 4.0
    static let defaultRestTime: Double = 2.0
    static let defaultBreakTime: Double = 6.0
//    static let defaultWorkTime: Double = 25.0 * 60.0
//    static let defaultRestTime: Double = 5.0 * 60.0
//    static let defaultBreakTime: Double = 30.0 * 60.0
    
    private var pomoAction: (PomoStatus) -> Void
    
    init(pomos: Int, longBreak: Double, perform action: @escaping (PomoStatus) -> Void) {
        pomoCount = pomos
        longBreakTime = longBreak
        pomoAction = action
        let pomoTimes = getPomoTimes(pomos, longBreak)
        let timeIntervals = pomoTimes.map { $0.getTime() }
        order = pomoTimes
        
        weak var selfInstance: PomoTimer?
        super.init(timeIntervals) { index in
            if index < pomoTimes.count {
                action(pomoTimes[index].getStatus())
            } else {
                selfInstance?.toggle()
                action(.end)
            }
        }
        selfInstance = self
    }
    
    
    public func getStatus(atDate: Date = Date()) -> PomoStatus {
        let index = getIndex(atDate: atDate)
        if index == order.count-1 && timeRemaining(atDate: atDate) == 0.0 {
            return .end
        }
        return order[index].getStatus()
    }
    
    public func getStatusString(atDate: Date = Date()) -> String {
        return getStatus(atDate: atDate).rawValue
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
        
        super.reset(timeIntervals) { index in
            if index < pomoTimes.count {
                self.pomoAction(pomoTimes[index].getStatus())
            } else {
                self.toggle()
                self.pomoAction(.end)
            }
        }
    }
    
    func reset() {
        super.reset([])
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
    
    
    func setupNotification() {
        guard !isPaused else { return }
        let now = Date()
        let currentIndex = getIndex(atDate: now)
        
        for index in currentIndex..<order.count {
            let timeToNext = timeRemaining(for: index, atDate: now)
            
            let content = UNMutableNotificationContent()
            
            switch getStatus(atDate: now.addingTimeInterval(timeToNext)) {
            case .work:
                content.title = "\(PomoStatus.work.rawValue) is over."
                content.subtitle = "🍅🍅🍅 Time to rest 🍅🍅🍅"
                content.sound = UNNotificationSound.default
            case .rest:
                content.title = "\(PomoStatus.rest.rawValue) is over."
                content.subtitle = index == order.count-2 ? "🍉🍇🍌 Take a long break 🍐🍊🍒" : "🌶️🌶️🌶️ Time to work 🌶️🌶️🌶️"
                content.sound = UNNotificationSound.default
            case .longBreak:
                content.title = "\(PomoStatus.longBreak.rawValue) is over."
                content.subtitle = "🍅🍅🍅"
                content.sound = UNNotificationSound.default
            case .end:
                content.title = "\(PomoStatus.longBreak.rawValue) is over."
                content.subtitle = "🎉🎉🎉 Finished 🎉🎉🎉"
                content.sound = UNNotificationSound.default
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeToNext > 0.0 ? timeToNext : 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
        
    }
    
    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
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
