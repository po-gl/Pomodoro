//
//  LiveActivities.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/23/23.
//

import ActivityKit
import WidgetKit
import SwiftUI
import BackgroundTasks
import OSLog

struct Payload: Codable {
    let timeIntervals: [PayloadTimeInterval]
}

struct PayloadTimeInterval: Codable {
    let status: String
    let task: String
    let startsAt: TimeInterval
    let currentSegment: Int
}

struct PushTokenPayload: Codable {
    let pushToken: String
}

class LiveActivities {
    static let shared = LiveActivities()

    @available(iOS 16.2, *)
    func setupLiveActivity(_ pomoTimer: PomoTimer, _ tasksOnBar: TasksOnBar) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard Activity<PomoAttributes>.activities.isEmpty else { return }
        guard !pomoTimer.isPaused else { return }

        sendPomoDataToServer(pomoTimer, tasksOnBar)

        let pomoAttrs = PomoAttributes(segmentCount: pomoTimer.order.count + 1) // + 1 for .end segment
        let content = getLiveActivityContent(pomoTimer, tasksOnBar)

        do {
            let activity = try Activity.request(attributes: pomoAttrs, content: content, pushType: .token)
            Logger().log("Requested live activity \(String(describing: activity.id)).")
            pollPushTokenUpdates(activity: activity)
        } catch {
            Logger().error("Error requesting live activity \(error.localizedDescription).")
        }
    }

    @available(iOS 16.2, *)
    private func getLiveActivityContent(_ pomoTimer: PomoTimer,
                                        _ tasksOnBar: TasksOnBar) -> ActivityContent<PomoAttributes.PomoState> {
        let i = pomoTimer.getIndex()
        let state = PomoAttributes.PomoState(
            status: pomoTimer.getStatus().rawValue,
            task: i < tasksOnBar.tasksOnBar.count ? tasksOnBar.tasksOnBar[i] : "",
            startTimestamp: Date().timeIntervalSince1970,
            currentSegment: i,
            timeRemaining: pomoTimer.timeRemaining(),
            isFirst: true)
        return ActivityContent(state: state, staleDate: nil)
    }

    @available(iOS 16.2, *)
    func pollPushTokenUpdates<T>(activity: Activity<T>) {
        Task {
            for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.map { String(format: "%02hhx", $0)}.joined()
                Logger().log("New push token: \(pushTokenString)")
                
                sendPushTokenToServer(pushTokenString)
            }
        }
    }

    @available(iOS 16.2, *)
    func cancelLiveActivity(_ pomoTimer: PomoTimer) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        cancelServerRequest()

        let finalStatus = PomoAttributes.PomoState(status: PomoStatus.end.rawValue,
                                                   task: "",
                                                   startTimestamp: Date().timeIntervalSince1970,
                                                   currentSegment: pomoTimer.order.count,
                                                   timeRemaining: 0, isFirst: false)
        let finalContent = ActivityContent(state: finalStatus, staleDate: nil)
        Task {
            for activity in Activity<PomoAttributes>.activities {
                await activity.end(finalContent, dismissalPolicy: .immediate)
            }
        }
    }

#if os(iOS)
    func sendPomoDataToServer(_ pomoTimer: PomoTimer, _ tasksOnBar: TasksOnBar) {
        guard let deviceToken = AppNotifications.shared.deviceToken else { return }
        guard pomoTimer.getStatus() != .end else { return }

        let url = URL(string: "http://127.0.0.1:9797/request/\(deviceToken)")!
        let payload = Payload(timeIntervals: pomoToPayloadTimeIntervals(pomoTimer, tasksOnBar))

        send(url: url, payload: payload)
    }

    func sendPushTokenToServer(_ pushToken: String) {
        guard let deviceToken = AppNotifications.shared.deviceToken else { return }

        let url = URL(string: "http://127.0.0.1:9797/pushtoken/\(deviceToken)")!
        let payload = PushTokenPayload(pushToken: pushToken)

        send(url: url, payload: payload)
    }

    func cancelServerRequest() {
        guard let deviceToken = AppNotifications.shared.deviceToken else { return }

        let url = URL(string: "http://127.0.0.1:9797/cancel/\(deviceToken)")!
        var req = URLRequest(url: url)

        req.httpMethod = "POST"

        send(url: url)
    }

    private func send(url: URL) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        executeURLDataTask(with: req)
    }

    private func send<T: Encodable>(url: URL, payload: T? = nil) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"

        if let payload {
            let encoder = JSONEncoder()
            guard let encodedPayload = try? encoder.encode(payload) else { return }
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = encodedPayload
        }
        executeURLDataTask(with: req)
    }

    private func executeURLDataTask(with req: URLRequest) {
        let task = URLSession.shared.dataTask(with: req) { _, res, err in
            if let err {
                Logger().error("Client error: \(err.localizedDescription)")
                return
            }
            guard let httpResponse = res as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                if let httpResponse = res as? HTTPURLResponse {
                    Logger().error("Server error: \(httpResponse.statusCode)")
                } else {
                    Logger().error("Server error: unknown")
                }
                return
            }
            Logger().log("HTTP response status: \(httpResponse.statusCode)")
        }
        task.resume()
    }

    private func pomoToPayloadTimeIntervals(_ pomoTimer: PomoTimer,
                                            _ tasksOnBar: TasksOnBar) -> [PayloadTimeInterval] {
        var timeIntervals: [PayloadTimeInterval] = []

        var cumulativeTime = pomoTimer.timeRemaining()
        for i in pomoTimer.getIndex()+1..<pomoTimer.order.count {
            let pomo = pomoTimer.order[i]
            
            let status = pomo.getStatusString().lowercased()
            let task = i < tasksOnBar.tasksOnBar.count ? tasksOnBar.tasksOnBar[i] : ""
            let startsAt = cumulativeTime + Date.now.timeIntervalSince1970
            
            timeIntervals.append(PayloadTimeInterval(status: status,
                                                     task: task,
                                                     startsAt: startsAt,
                                                     currentSegment: i))
            cumulativeTime += pomo.getTime()
        }
        timeIntervals.append(PayloadTimeInterval(status: PomoStatus.end.rawValue.lowercased(),
                                                 task: "",
                                                 startsAt: cumulativeTime + Date.now.timeIntervalSince1970,
                                                 currentSegment: pomoTimer.order.count))
        return timeIntervals
    }
#endif
}
