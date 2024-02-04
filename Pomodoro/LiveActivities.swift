//
//  LiveActivities.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/23/23.
//

#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI
import BackgroundTasks
import OSLog

struct Payload: Codable {
    let timeIntervals: [PayloadTimeInterval]
    let segmentCount: Int
}

struct PayloadTimeInterval: Codable {
    let status: String
    let task: String
    let startsAt: TimeInterval
    let currentSegment: Int
    let alert: PayloadAlert
}

struct PayloadAlert: Codable {
    let title: String
    let body: String
    let sound: String
}

struct PushTokenPayload: Codable {
    let pushToken: String
}

@available(iOS 16.1, *)
class LiveActivities {
    static let shared = LiveActivities()

    static let serverURL = Env.shared.vars?.serverURL ?? "http://127.0.0.1:9000"

    var deviceToken: String? {
        UserDefaults.pomo?.string(forKey: "deviceToken")
    }

    var pushTokenPollingTask: Task<(), Never>?

    @available(iOS 16.2, *)
    func setupLiveActivity(_ pomoTimer: PomoTimer, _ tasksOnBar: TasksOnBar) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !pomoTimer.isPaused else { return }

        Logger().log("URL to live activity server: \(LiveActivities.serverURL)")

        Task {
            do {
                try await waitForDeviceToken()

                try await sendPomoDataToServer(pomoTimer, tasksOnBar)

                let pomoAttrs = PomoAttributes(workDuration: pomoTimer.workDuration,
                                               restDuration: pomoTimer.restDuration,
                                               breakDuration: pomoTimer.breakDuration)
                let content = getLiveActivityContentFor(pomoTimer, tasksOnBar)

                if let activity = Activity<PomoAttributes>.activities.first {
                    await activity.update(content)
                    Logger().log("Updated live activity \(String(describing: activity.id)).")
                } else {
                    let activity = try Activity.request(attributes: pomoAttrs, content: content, pushType: .token)
                    Logger().log("Requested live activity \(String(describing: activity.id)).")

                    startPollingPushTokenUpdates()
                }
            } catch {
                Logger().error("Error requesting live activity: \(error.localizedDescription)")
                cancelLiveActivity(pomoTimer)
            }
        }
    }

    @available(iOS 16.2, *)
    func stopLiveActivity(_ pomoTimer: PomoTimer, _ tasksOnBar: TasksOnBar) {
        Task {
            do {
                if let activity = Activity<PomoAttributes>.activities.first {
                    let content = getLiveActivityContentFor(pomoTimer, tasksOnBar)
                    await activity.update(content)
                    Logger().log("Updated live activity \(String(describing: activity.id)).")
                }
                try await cancelServerRequest()
            } catch {
                Logger().error("Error stopping live activyt: \(error.localizedDescription)")
            }
        }
    }

    @available(iOS 16.2, *)
    func getLiveActivityContentFor(_ pomoTimer: PomoTimer,
                                   _ tasksOnBar: TasksOnBar) -> ActivityContent<PomoAttributes.PomoState> {
        let i = pomoTimer.getStatus() == .end ? pomoTimer.order.count : pomoTimer.getIndex()
        let state = PomoAttributes.PomoState(
            status: pomoTimer.getStatus().rawValue,
            task: i < tasksOnBar.tasksOnBar.count ? tasksOnBar.tasksOnBar[i] : "",
            startTimestamp: Date().timeIntervalSince1970,
            currentSegment: i,
            segmentCount: pomoTimer.order.count + 1, // +1 for .end segment
            timeRemaining: pomoTimer.timeRemaining(),
            isFullSegment: false,
            isPaused: pomoTimer.isPaused)
        return ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(pomoTimer.timeRemaining() + 5))
    }

    @available(iOS 16.2, *)
    func startPollingPushTokenUpdates() {
        guard let activity = Activity<PomoAttributes>.activities.first else { return }

        LiveActivities.shared.pushTokenPollingTask?.cancel()

        LiveActivities.shared.pushTokenPollingTask = Task {
            for await pushToken in activity.pushTokenUpdates {
                guard !Task.isCancelled else { break; }

                let pushTokenString = pushToken.map { String(format: "%02hhx", $0)}.joined()
                Logger().log("New push token: \(pushTokenString)")
                do {
                    try await sendPushTokenToServer(pushTokenString)
                } catch {
                    Logger().error("Error sending push token to server: \(error.localizedDescription)")
                }
            }
        }
    }

    @available(iOS 16.2, *)
    func cancelLiveActivity(_ pomoTimer: PomoTimer) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task {
            try? await cancelServerRequest()
        }

        let finalStatus = PomoAttributes.PomoState(status: PomoStatus.end.rawValue,
                                                   task: "",
                                                   startTimestamp: Date().timeIntervalSince1970,
                                                   currentSegment: pomoTimer.order.count,
                                                   segmentCount: pomoTimer.order.count + 1, // +1 for .end segment
                                                   timeRemaining: 0, isFullSegment: true, isPaused: true)
        let finalContent = ActivityContent(state: finalStatus, staleDate: Date.now.addingTimeInterval(10))
        Task {
            for activity in Activity<PomoAttributes>.activities {
                await activity.end(finalContent, dismissalPolicy: .immediate)
            }
        }
    }

    /// Wait for device token with exponential backoff
    private func waitForDeviceToken() async throws {
        let attemptLimit = 8
        var attempt = 0
        var expSeconds = 2.0

        while attempt < attemptLimit {
            if deviceToken != nil {
                return
            }
            try? await Task.sleep(for: .seconds(expSeconds))
            expSeconds = expSeconds * expSeconds
            attempt += 1
        }
        throw LiveActivityError.missingDeviceToken
    }

    func sendPomoDataToServer(_ pomoTimer: PomoTimer, _ tasksOnBar: TasksOnBar) async throws {
        guard let deviceToken else { return }
        guard pomoTimer.getStatus() != .end else { return }

        guard let url = URL(string: "\(LiveActivities.serverURL)/request/\(deviceToken)") else { throw LiveActivityError.badURL }
        let payload = Payload(timeIntervals: pomoToPayloadTimeIntervals(pomoTimer, tasksOnBar),
                              segmentCount: pomoTimer.order.count + 1) // +1 for .end segment

        try await send(url: url, payload: payload)
    }

    func sendPushTokenToServer(_ pushToken: String) async throws {
        guard let deviceToken else { return }

        guard let url = URL(string: "\(LiveActivities.serverURL)/pushtoken/\(deviceToken)") else { throw LiveActivityError.badURL }
        let payload = PushTokenPayload(pushToken: pushToken)

        try await send(url: url, payload: payload)
    }

    func cancelServerRequest() async throws {
        guard let deviceToken else { return }

        guard let url = URL(string: "\(LiveActivities.serverURL)/cancel/\(deviceToken)") else { throw LiveActivityError.badURL }
        var req = URLRequest(url: url)

        req.httpMethod = "POST"

        try await send(url: url)
    }

    private func send(url: URL) async throws {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        try await executeURLDataTask(with: req)
    }

    private func send<T: Encodable>(url: URL, payload: T? = nil) async throws {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"

        if let payload {
            let encoder = JSONEncoder()
            guard let encodedPayload = try? encoder.encode(payload) else { return }
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = encodedPayload
        }
        try await executeURLDataTask(with: req)
    }

    private func executeURLDataTask(with req: URLRequest) async throws {
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            if let response = response as? HTTPURLResponse {
                guard (200...299).contains(response.statusCode) else {
                    Logger().error("HTTP error: \(response.statusCode)")
                    throw LiveActivityError.notOkResponse
                }
                Logger().log("HTTP response status: \(response.statusCode)")
            }
        } catch {
            Logger().error("Error executing url data task: \(error.localizedDescription)")
            throw error
        }
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
            
            let alertContent = AppNotifications.shared.getNotificationContent(for: pomoTimer, at: i-1)
            let alert = PayloadAlert(title: alertContent.title, body: alertContent.body, sound: "default")

            timeIntervals.append(PayloadTimeInterval(status: status,
                                                     task: task,
                                                     startsAt: startsAt,
                                                     currentSegment: i,
                                                     alert: alert))
            cumulativeTime += pomo.getTime()
        }
        
        let finalAlertContent = AppNotifications.shared.getNotificationContent(for: pomoTimer, at: pomoTimer.order.count-1)
        let finalAlert = PayloadAlert(title: finalAlertContent.title, body: finalAlertContent.body, sound: "default")
        timeIntervals.append(PayloadTimeInterval(status: PomoStatus.end.rawValue.lowercased(),
                                                 task: "",
                                                 startsAt: cumulativeTime + Date.now.timeIntervalSince1970,
                                                 currentSegment: pomoTimer.order.count,
                                                 alert: finalAlert))
        return timeIntervals
    }
}

enum LiveActivityError: Error {
    case notOkResponse
    case badURL
    case missingDeviceToken
}

extension LiveActivityError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notOkResponse:
            NSLocalizedString("Not OK response from remote server.", comment: "")
        case .badURL:
            NSLocalizedString("Bad URL", comment: "")
        case .missingDeviceToken:
            NSLocalizedString("Missing Device Token", comment: "")
        }
    }
}
#endif
