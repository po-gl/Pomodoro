//
//  PomodoroWatchApp.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/23/22.
//

import SwiftUI
import WatchConnectivity
import WidgetKit

@main
struct PomodoroWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .backgroundTask(.watchConnectivity) {
            updateComplication(session: WCSession.default)
        }
    }
    
    private func updateComplication(session: WCSession) {
        if let userInfo = session.outstandingUserInfoTransfers.first?.userInfo {
            if let isComplicationInfo = userInfo[PayloadKey.isComplicationInfo] as? Bool, isComplicationInfo == true {
                if let pomoData = userInfo[PayloadKey.pomoTimer] as? Data {
                    if let pomoTimer = try? PropertyListDecoder().decode(PomoTimer.self, from: pomoData) {
                        pomoTimer.saveToUserDefaults()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
    }
}
