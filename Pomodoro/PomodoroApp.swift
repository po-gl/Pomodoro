//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif
import WatchConnectivity
import Combine
import OSLog

@main
struct PomodoroApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    let persistenceController = PersistenceController.shared

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager

    @ObservedObject var pomoTimer: PomoTimer
    @StateObject var tasksOnBar = TasksOnBar.shared

    @State var didReceiveSyncFromWatchConnection = false
    @State var didPerformInactiveSetup = false

    init() {
        let workDuration = UserDefaults.pomo?.value(forKey: "workDuration") as? Double ?? PomoTimer.defaultWorkTime
        let restDuration = UserDefaults.pomo?.value(forKey: "restDuration") as? Double ?? PomoTimer.defaultRestTime
        let breakDuration = UserDefaults.pomo?.value(forKey: "breakDuration") as? Double ?? PomoTimer.defaultBreakTime
        pomoTimer = PomoTimer(pomos: 4,
                              work: workDuration,
                              rest: restDuration,
                              longBreak: breakDuration,
                              context: persistenceController.container.viewContext) { status in
            EndTimerHandler.shared.handle(status: status)
        }
        pomoTimer.restoreFromUserDefaults()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(pomoTimer)
                .environmentObject(tasksOnBar)
                .onAppear {
                    AppNotifications.shared.getNotificationPermissions()
                    viewContext.undoManager = undoManager
                }

                .onChange(of: scenePhase) { newPhase in
                    Logger().log("Phase \(newPhase)")
                    if newPhase == .active {
                        pomoTimer.restoreFromUserDefaults()
                        AppNotifications.shared.cancelPendingNotifications()
                        setupWatchConnection()
                        didPerformInactiveSetup = false
                        if #available(iOS 16.2, *) {
#if canImport(ActivityKit)
                            LiveActivities.shared.startPollingPushTokenUpdates()
#endif
                        }
                        UIApplication.shared.registerForRemoteNotifications()

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
                    UIApplication.shared.registerForRemoteNotifications()

                    if #available(iOS 16.2, *) {
#if canImport(ActivityKit)
                        Task { @MainActor in
                            if isPaused {
                                await LiveActivities.shared.stopLiveActivity(pomoTimer, tasksOnBar)
                            } else {
                                await LiveActivities.shared.setupLiveActivity(pomoTimer, tasksOnBar)
                            }
                        }
#endif
                    }
#if targetEnvironment(macCatalyst)
                    if !isPaused {
                        Task { await AppNotifications.shared.setupNotifications(pomoTimer) }
                    }
#endif
                }
                .onChange(of: pomoTimer.isReset) { isReset in
                    if isReset {
                        WidgetCenter.shared.reloadAllTimelines()
                        let wcSent = updateWatchConnection(pomoTimer)
                        didReceiveSyncFromWatchConnection = !wcSent
                        
                        if #available(iOS 16.2, *) {
#if canImport(ActivityKit)
                            Task { @MainActor in
                                await LiveActivities.shared.stopLiveActivity(pomoTimer, tasksOnBar)
                            }
#endif
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
#if targetEnvironment(macCatalyst)
                .frame(minWidth: 600, idealWidth: 700, minHeight: 900, idealHeight: 1000)
#endif
        }
#if targetEnvironment(macCatalyst)
        .backDeployedDefaultSize(width: 700, height: 1000)
#endif
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.map { String(format: "%02hhx", $0)}.joined()
        Logger().log("Device token: \(deviceTokenString)")
        UserDefaults.pomo?.set(deviceTokenString, forKey: "deviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger().error("Failed to register remote noticiations: \(error.localizedDescription)")
    }
}
