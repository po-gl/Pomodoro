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
    
    @State var scrollValue = 0.0
    
    var body: some View {
        VStack {
            GeometryReader { metrics in
                VStack {
                    TimerDisplay(pomoTimer: pomoTimer)
                    Spacer()
                    ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                        .digitalCrownRotation($scrollValue, from: 0.0, through: 100,
                                              sensitivity: .medium,
                                              isHapticFeedbackEnabled: true,
                                              onChange: { event in pomoTimer.setPercentage(to: event.offset.rounded() / 100) })
                        .onChange(of: pomoTimer.isPaused) { _ in scrollValue = pomoTimer.getCurrentPercentage() * 100.0 }
                        .onChange(of: pomoTimer.getStatus()) { _ in basicHaptic() }
                        .focusable(pomoTimer.isPaused)
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
