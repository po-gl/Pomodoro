//
//  AppNotifications.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/25/22.
//

import Foundation
import SwiftUI

#if os(iOS)
import ActivityKit
#endif

#if os(watchOS)
import WatchKit
import UserNotifications
#endif

class AppNotifications {
    static let shared = AppNotifications()

    public var deviceToken: String?

    func getNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                print("There was an error requesting permissions: \(error.localizedDescription)")
            }
        }
    }

    func setupNotifications(_ pomoTimer: PomoTimer) async {
        guard !pomoTimer.isPaused else { return }
        guard await UNUserNotificationCenter.current().pendingNotificationRequests().isEmpty else { return }
#if os(iOS)
        if #available(iOS 16.1, *) {
            guard Activity<PomoAttributes>.activities.isEmpty else { return }
        }
        
        let currentIndex = pomoTimer.getIndex(atDate: Date.now)
#elseif os(watchOS)
        // watchOS uses BackgroundSession to handle the first notification
        let currentIndex = pomoTimer.getIndex(atDate: Date.now) + 1
#endif
        
        for index in currentIndex..<pomoTimer.order.count {
            let content = getNotificationContent(for: pomoTimer, at: index)
            
            let timeToNext = pomoTimer.timeRemaining(for: index, atDate: Date.now)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeToNext > 0.0 ? timeToNext : 0.1,
                                                            repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Error adding notification \(error.localizedDescription)")
            }
        }
    }
    
    private func getNotificationContent(for pomoTimer: PomoTimer, at index: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let now = Date.now
        let timeToNext = pomoTimer.timeRemaining(for: index, atDate: now)
        
        switch pomoTimer.getStatus(atDate: now.addingTimeInterval(timeToNext)) {
        case .work:
            let endOfNext = now.addingTimeInterval(pomoTimer.timeRemaining(for: index+1, atDate: now))
            content.title = "Time to rest"
            content.body = "Work is over, take a breather until \(timeFormatter.string(from: endOfNext))."
            content.sound = UNNotificationSound.default
        case .rest:
            let endOfNext = now.addingTimeInterval(pomoTimer.timeRemaining(for: index+1, atDate: now))
            if index == pomoTimer.order.count-2 {
                content.title = "Take a long break"
                content.body = "Relax until \(timeFormatter.string(from: endOfNext))."
            } else {
                content.title = "Time to work"
                content.body = "Your rest is over, work until \(timeFormatter.string(from: endOfNext))."
            }
            content.sound = UNNotificationSound.default
        case .longBreak:
            content.title = "\(PomoStatus.longBreak.rawValue) is over."
            content.body = "🍅🍅🍅"
            content.sound = UNNotificationSound.default
        case .end:
            let celebration: [String] = ["hike", "walk", "favorite snack"]
            content.title = "Your pomodoros are done! 🎉"
            content.body = "Celebrate with a \(celebration.randomElement()!)!"
            content.sound = UNNotificationSound.default
        }
        return content
    }
    
    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("hh:mm")
        return formatter
    }()
}

