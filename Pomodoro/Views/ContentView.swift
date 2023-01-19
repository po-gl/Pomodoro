//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import CoreHaptics

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var pomoTimer: PomoTimer
    
    @State private var haptics = Haptics()
    
    
    init() {
        var selfInstance: ContentView?
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            selfInstance?.handleTimerEnd(status: status)
        }
        selfInstance = self
        
        pomoTimer.pause()
        pomoTimer.saveToUserDefaults()
    }

    
    var body: some View {
        mainPage()
            .onAppear {
                getNotificationPermissions()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    pomoTimer.restoreFromUserDefaults()
                    cancelPendingNotifications()
                    haptics.prepareHaptics()
                } else if newPhase == .inactive {
                    pomoTimer.saveToUserDefaults()
                    setupNotifications(pomoTimer)
                }
            }
    }
    
    
    private func mainPage() -> some View {
        return GeometryReader { metrics in
            ZStack {
                Background(pomoTimer: pomoTimer)
                VStack {
                    Spacer()
                    TimerDisplay(pomoTimer: pomoTimer)
                    Spacer()
                    Spacer()
                    ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                        .frame(maxHeight: 130)
                    Spacer()
                    ButtonCluster(pomoTimer: pomoTimer)
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: pomoTimer.isPaused)
        }
    }
    
    
    private func handleTimerEnd(status: PomoStatus) {
        switch status {
        case .work:
            haptics.workHaptic()
        case .rest:
            haptics.restHaptic()
        case .longBreak:
            haptics.breakHaptic()
        case .end:
            haptics.breakHaptic()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
