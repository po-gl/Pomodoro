//
//  BackgroundSession.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/11/23.
//

import Foundation
import WatchKit
import OSLog

class BackgroundSession: NSObject, WKExtendedRuntimeSessionDelegate {
    static var shared = BackgroundSession()
    var session = WKExtendedRuntimeSession()

    func startIfUnpaused(for pomoTimer: PomoTimer) {
        if !pomoTimer.isPaused && pomoTimer.getStatus() != .end {
            // Add 1 second so we can invalidate the session if app is active
            start(at: .now + pomoTimer.timeRemaining() + 1)
        }
    }

    func start(at date: Date) {
        guard session.state != .running else { return }

        session = WKExtendedRuntimeSession()
        session.delegate = self

        Logger().log("Background Session starting at \(timeFormatter.string(from: date))")
        session.start(at: date)
    }

    func stop() {
        Logger().log("Background Session stopped")
        session.invalidate()
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Logger().log("BackgroundSession: did start and should notify")
        extendedRuntimeSession.notifyUser(hapticType: .notification)
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Logger().log("BackgroundSession: end")
        extendedRuntimeSession.invalidate()
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        if let error {
            Logger().error("Error occurred during background session: \(error.localizedDescription)")
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm:ss")
    return formatter
}()
