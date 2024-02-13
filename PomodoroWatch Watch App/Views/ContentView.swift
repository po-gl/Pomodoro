//
//  ContentView.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/23/22.
//

import SwiftUI
import WidgetKit
import WatchConnectivity
import Combine
import OSLog

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @ObservedObject var pomoTimer: PomoTimer

    @State var didReceiveSyncFromWatchConnection = false
    @State var didPerformInactiveSetup = false

    init() {
        let workDuration = UserDefaults.pomo?.value(forKey: "workDuration") as? Double ?? PomoTimer.defaultWorkTime
        let restDuration = UserDefaults.pomo?.value(forKey: "restDuration") as? Double ?? PomoTimer.defaultRestTime
        let breakDuration = UserDefaults.pomo?.value(forKey: "breakDuration") as? Double ?? PomoTimer.defaultBreakTime
        pomoTimer = PomoTimer(pomos: 4, work: workDuration, rest: restDuration, longBreak: breakDuration) { status in
            EndTimerHandler.shared.handle(status: status)
        }
        pomoTimer.restoreFromUserDefaults()
    }

    var body: some View {
        TabView {
            MainPage()
            GeometryReader { geometry in
                SettingsPage(geometry: geometry)
            }
        }
        .environmentObject(pomoTimer)
        .opacity(isLuminanceReduced ? 0.6 : 1.0)
        .onAppear {
            AppNotifications.shared.getNotificationPermissions()
            startBackgroundSessionIfDidNotReceiveWCSync()
        }
        .onChange(of: scenePhase) {
            Logger().log("Phase \(scenePhase)")
            if scenePhase == .active {
                pomoTimer.restoreFromUserDefaults()
                AppNotifications.shared.cancelPendingNotifications()
                setupWatchConnection()

                BackgroundSession.shared.stop()
                startBackgroundSessionIfDidNotReceiveWCSync()

                didPerformInactiveSetup = false

            } else if scenePhase == .inactive || scenePhase == .background {
                guard !didPerformInactiveSetup else { return }
                pomoTimer.saveToUserDefaults()
                WidgetCenter.shared.reloadAllTimelines()
                if !didReceiveSyncFromWatchConnection {
                    Task { await AppNotifications.shared.setupNotifications(pomoTimer) }
                }
                didPerformInactiveSetup = true
            }
        }

        .onChange(of: pomoTimer.isPaused) {
            if pomoTimer.isPaused {
                BackgroundSession.shared.stop()
            } else {
                startBackgroundSessionIfDidNotReceiveWCSync()
            }
            WidgetCenter.shared.reloadAllTimelines()
            let wcSent = updateWatchConnection(pomoTimer)
            didReceiveSyncFromWatchConnection = !wcSent
        }
        .onChange(of: pomoTimer.isReset) {
            if pomoTimer.isReset {
                WidgetCenter.shared.reloadAllTimelines()
                let wcSent = updateWatchConnection(pomoTimer)
                didReceiveSyncFromWatchConnection = !wcSent
            }
        }
        .onChange(of: pomoTimer.getStatus()) {
            Task {
                try? await Task.sleep(for: .seconds(1))
                startBackgroundSessionIfDidNotReceiveWCSync()
            }
        }

        .onReceive(Publishers.wcSessionDataDidFlow) { timer in
            if let timer {
                Logger().debug("\(#function): watchOS received pomoTimer.pomoCount=\(timer.pomoCount) isPaused=\(timer.isPaused)")
                pomoTimer.sync(with: timer)
                pomoTimer.saveToUserDefaults()
                didReceiveSyncFromWatchConnection = true
            }
        }
    }

    private func startBackgroundSessionIfDidNotReceiveWCSync() {
        if !didReceiveSyncFromWatchConnection {
            BackgroundSession.shared.startIfUnpaused(for: pomoTimer)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["Apple Watch Series 7 (41mm)", "Apple Watch Series 7 (45mm)", "Apple Watch Series 6 (38mm)"], id: \.self) { deviceName in
            ContentView()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}
