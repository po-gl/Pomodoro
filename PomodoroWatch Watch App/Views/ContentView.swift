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
    @ObservedObject var pomoTimer: PomoTimer
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            switch status {
            case .work:
                workHaptic()
            case .rest:
                restHaptic()
            case .longBreak:
                breakHaptic()
            case .end:
                breakHaptic()
            }
        }
        
        pomoTimer.pause()
    }
    
    var body: some View {
        TabView {
            MainPage(pomoTimer: pomoTimer)
            ChangerPage(pomoTimer: pomoTimer)
        }
            .onAppear {
                getNotificationPermissions()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    print("\nActive")
                    pomoTimer.restoreFromUserDefaults()
                    cancelPendingNotifications()
                } else if newPhase == .inactive {
                    print("\nInactive")
                    pomoTimer.saveToUserDefaults()
                    setupNotifications(pomoTimer)
                    WidgetCenter.shared.reloadAllTimelines()
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
