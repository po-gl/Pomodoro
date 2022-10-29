//
//  MainPage.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/28/22.
//

import SwiftUI
import WidgetKit

struct MainPage: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        VStack {
            GeometryReader { metrics in
                VStack {
                    TimerDisplay(pomoTimer: pomoTimer)
                    Spacer()
                    ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                    Spacer()
                    Spacer()
                    ButtonCluster(pomoTimer: pomoTimer)
                        .padding(.bottom)
                }
                .ignoresSafeArea()
                .padding(.top)
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
}
