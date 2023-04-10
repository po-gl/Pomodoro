//
//  ContentView.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/23/22.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @ObservedObject var pomoTimer: PomoTimer
    
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
            BackgroundSession.shared.startIfUnpaused(for: pomoTimer)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("Active")
                pomoTimer.restoreFromUserDefaults()
                cancelPendingNotifications()
                
                BackgroundSession.shared.stop()
                BackgroundSession.shared.startIfUnpaused(for: pomoTimer)
                
            } else if newPhase == .inactive || newPhase == .background {
                print("Inactive")
                pomoTimer.saveToUserDefaults()
                Task { await setupNotifications(pomoTimer) }
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        .onChange(of: pomoTimer.isPaused) { _ in
            if pomoTimer.isPaused {
                BackgroundSession.shared.stop()
            } else {
                BackgroundSession.shared.startIfUnpaused(for: pomoTimer)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: pomoTimer.getStatus()) { _ in
            Task {
                try? await Task.sleep(for: .seconds(1))
                BackgroundSession.shared.startIfUnpaused(for: pomoTimer)
            }
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
