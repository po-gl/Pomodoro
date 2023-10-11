//
//  WatchConnection.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/9/23.
//

import SwiftUI
import WatchConnectivity
import Combine
import WidgetKit

func setupWatchConnection() {
    if WCSession.isSupported() {
        let session = WCSession.default
        session.delegate = SessionDelegate.shared
        session.activate()
    }
}

@discardableResult
func updateWatchConnection(_ pomoTimer: PomoTimer) -> Bool {
    guard WCSession.isSupported() else { return false }
    let session = WCSession.default

    if let lastReceivedTime = SessionDelegate.lastReceived?.timeIntervalSince1970 {
        guard Date().timeIntervalSince1970 - lastReceivedTime > 0.05 else {
            print("Skipped updateWatchConnection")
            return false
        }
    }

    let data = try? PropertyListEncoder().encode(pomoTimer)
    guard let pomoData = data else {
        print("Failed to encode pomoTimer")
        return false
    }

    wcSendMessage(pomoData, session: session)
#if os(iOS)
    wcUpdateComplication(pomoData, session: session)
#endif
    return true
}

private func wcSendMessage(_ pomoData: Data, session: WCSession) {
    session.sendMessage([
        PayloadKey.pomoTimer: pomoData,
        PayloadKey.isComplicationInfo: false,
        PayloadKey.date: Date()
    ], replyHandler: nil, errorHandler: { error in
        print("Error sending WC message: \(error.localizedDescription)")
        do {
            try session.updateApplicationContext([
                PayloadKey.pomoTimer: pomoData,
                PayloadKey.isComplicationInfo: false,
                PayloadKey.date: Date()
            ])
        } catch {
            print("Failed to call .updateApplicationContext")
        }
    })
}

#if os(iOS)
private func wcUpdateComplication(_ pomoData: Data, session: WCSession) {
    guard session.remainingComplicationUserInfoTransfers > 0 else { return }

    session.transferCurrentComplicationUserInfo([
        PayloadKey.pomoTimer: pomoData,
        PayloadKey.isComplicationInfo: true,
        PayloadKey.date: Date()
    ])
}
#endif

struct PayloadKey {
    static let pomoTimer = "pomoTimer"
    static let date = "date"
    static let isComplicationInfo = "isComplicationInfo"
}

extension Notification.Name {
    static let dataDidFlow = Notification.Name("dataDidFlow")
    static let activationDidComplete = Notification.Name("activationDidComplete")
}

extension Publishers {
    static var wcSessionActivationDidComplete: AnyPublisher<Bool, Never> {
        let activationDidComplete = NotificationCenter.default.publisher(for: .activationDidComplete).map { _ in true }
        return activationDidComplete.eraseToAnyPublisher()
    }

    static var wcSessionDataDidFlow: AnyPublisher<PomoTimer?, Never> {
        let didFlow = NotificationCenter.default.publisher(for: .dataDidFlow)
            .map { $0.pomoTimer }
        return didFlow.eraseToAnyPublisher()
    }
}

extension Notification {
    var pomoTimer: PomoTimer? {
        if let pomoData = userInfo?[PayloadKey.pomoTimer] as? Data {
            if let pomoTimer = try? PropertyListDecoder().decode(PomoTimer.self, from: pomoData) {
                return pomoTimer
            }
        }
        return nil
    }

    var wcDate: Date? {
        return userInfo?[PayloadKey.date] as? Date
    }
}

class SessionDelegate: NSObject, WCSessionDelegate {

    static let shared = SessionDelegate()

    static var lastReceived: Date?

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
        postNotificationOnMainQueueAsync(name: .activationDidComplete)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Self.lastReceived = Date()
        postNotificationOnMainQueueAsync(name: .dataDidFlow, userInfo: applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Self.lastReceived = Date()
        postNotificationOnMainQueueAsync(name: .dataDidFlow, userInfo: message)
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif

    private func postNotificationOnMainQueueAsync(name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        Task {
            await MainActor.run {
                NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
            }
        }
    }
}
