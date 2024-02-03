//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import OSLog

@main
struct PomodoroApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
        AppNotifications.shared.deviceToken = deviceTokenString
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger().error("Failed to register remote noticiations: \(error.localizedDescription)")
    }
}
