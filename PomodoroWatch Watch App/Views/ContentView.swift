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

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var didReceiveSyncFromWatchConnection = false
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            EndTimerHandler.shared.handle(status: status)
        }
        pomoTimer.pause()
        pomoTimer.restoreFromUserDefaults()
    }
    
    var body: some View {
        TabView {
            MainPage(pomoTimer: pomoTimer)
            ChangerPage(pomoTimer: pomoTimer)
        }
        .opacity(isLuminanceReduced ? 0.6 : 1.0)
        .onAppear {
            getNotificationPermissions()
            startBackgroundSessionIfDidNotReceiveWCSync()
        }
        .onChange(of: scenePhase) { newPhase in
            print("Phase \(newPhase)")
            if newPhase == .active {
                pomoTimer.restoreFromUserDefaults()
                cancelPendingNotifications()
                setupWatchConnection()
                
                BackgroundSession.shared.stop()
                startBackgroundSessionIfDidNotReceiveWCSync()
                
            } else if newPhase == .inactive || newPhase == .background {
                pomoTimer.saveToUserDefaults()
                WidgetCenter.shared.reloadAllTimelines()
                if !didReceiveSyncFromWatchConnection {
                    Task { await setupNotifications(pomoTimer) }
                }
            }
        }
        
        .onChange(of: pomoTimer.isPaused) { _ in
            if pomoTimer.isPaused {
                BackgroundSession.shared.stop()
            } else {
                startBackgroundSessionIfDidNotReceiveWCSync()
            }
            WidgetCenter.shared.reloadAllTimelines()
            let wcSent = updateWatchConnection(pomoTimer)
            didReceiveSyncFromWatchConnection = !wcSent
        }
        .onChange(of: pomoTimer.getStatus()) { _ in
            Task {
                try? await Task.sleep(for: .seconds(1))
                startBackgroundSessionIfDidNotReceiveWCSync()
            }
        }
        
        .onReceive(Publishers.wcSessionDataDidFlow) { timer in
            if let timer {
                print("\(#function): watchOS received pomoTimer.pomoCount=\(timer.pomoCount) isPaused=\(timer.isPaused)")
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
