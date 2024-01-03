//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import CoreHaptics
import WidgetKit
import ActivityKit
import WatchConnectivity
import Combine
import OSLog

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager

    @ObservedObject var errors = Errors.shared

    @ObservedObject var pomoTimer: PomoTimer
    @StateObject var tasksOnBar = TasksOnBar()

    @State var didReceiveSyncFromWatchConnection = false
    @State var didPerformInactiveSetup = false

    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            EndTimerHandler.shared.handle(status: status)
        }
        pomoTimer.pause()
        pomoTimer.restoreFromUserDefaults()
    }

    var body: some View {
        TabView {
            MainPage()
                .reverseStatusBarColor()
                .tabItem { Label("Pomodoro", systemImage: "timer") }
            TaskList()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .badge(errors.coreDataError != nil ? "!" : nil)
            SettingsPage()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .environmentObject(pomoTimer)
        .environmentObject(tasksOnBar)
        .onAppear {
            AppNotifications.shared.getNotificationPermissions()
            UIApplication.shared.registerForRemoteNotifications()
            viewContext.undoManager = undoManager
        }
        
        .onChange(of: scenePhase) { newPhase in
            Logger().log("Phase \(newPhase)")
            if newPhase == .active {
                pomoTimer.restoreFromUserDefaults()
                AppNotifications.shared.cancelPendingNotifications()
                Haptics.shared.prepareHaptics()
                setupWatchConnection()
                didPerformInactiveSetup = false
                if #available(iOS 16.2, *) {
                    LiveActivities.shared.startPollingPushTokenUpdates()
                }
                
            } else if newPhase == .inactive || newPhase == .background {
                guard !didPerformInactiveSetup else { return }
                pomoTimer.saveToUserDefaults()
                WidgetCenter.shared.reloadAllTimelines()
                if !didReceiveSyncFromWatchConnection {
                    Task { await AppNotifications.shared.setupNotifications(pomoTimer) }
                }
                didPerformInactiveSetup = true
            }
        }
        
        .onChange(of: pomoTimer.isPaused) { isPaused in
            WidgetCenter.shared.reloadAllTimelines()
            let wcSent = updateWatchConnection(pomoTimer)
            didReceiveSyncFromWatchConnection = !wcSent
            
            if #available(iOS 16.2, *) {
                if isPaused {
                    LiveActivities.shared.stopLiveActivity(pomoTimer, tasksOnBar)
                } else {
                    LiveActivities.shared.setupLiveActivity(pomoTimer, tasksOnBar)
                }
            }
        }
        .onChange(of: pomoTimer.isReset) { isReset in
            if isReset {
                WidgetCenter.shared.reloadAllTimelines()
                let wcSent = updateWatchConnection(pomoTimer)
                didReceiveSyncFromWatchConnection = !wcSent
                
                if #available(iOS 16.2, *) {
                    LiveActivities.shared.stopLiveActivity(pomoTimer, tasksOnBar)
                }
            }
        }
        
        .onReceive(Publishers.wcSessionDataDidFlow) { timer in
            if let timer {
                Logger().debug("iOS received pomoTimer.pomoCount=\(timer.pomoCount) isPaused=\(timer.isPaused)")
                pomoTimer.sync(with: timer)
                pomoTimer.saveToUserDefaults()
                didReceiveSyncFromWatchConnection = true
            }
        }
        
        .onOpenURL { url in
            switch url.absoluteString {
            case "com.po-gl.pause":
                pomoTimer.pause()
                pomoTimer.saveToUserDefaults()
            case "com.po-gl.unpause":
                pomoTimer.unpause()
                pomoTimer.saveToUserDefaults()
            default:
                Logger().error("Unhandled url: \(url.absoluteString)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 14 Pro", "iPhone 13 mini"], id: \.self) { device in
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
        }
    }
}
