//
//  Notifications.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/25/22.
//

import Foundation
import SwiftUI

func setupNotifications(_ pomoTimer: PomoTimer) {
    guard !pomoTimer.isPaused else { return }
    let now = Date()
    let currentIndex = pomoTimer.getIndex(atDate: now)
    
    for index in currentIndex..<pomoTimer.order.count {
        let timeToNext = pomoTimer.timeRemaining(for: index, atDate: now)
        
        let content = UNMutableNotificationContent()
        
        switch pomoTimer.getStatus(atDate: now.addingTimeInterval(timeToNext)) {
        case .work:
            content.title = "\(PomoStatus.work.rawValue) is over."
            content.subtitle = "🍅🍅🍅 Time to rest 🍅🍅🍅"
            content.sound = UNNotificationSound.default
        case .rest:
            content.title = "\(PomoStatus.rest.rawValue) is over."
            content.subtitle = index == pomoTimer.order.count-2 ? "🍉🍇🍌 Take a long break 🍐🍊🍒" : "🌶️🌶️🌶️ Time to work 🌶️🌶️🌶️"
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
