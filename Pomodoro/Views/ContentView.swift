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
            print("Performed action! \(Date()) \(status)")
            selfInstance?.handleTimerEnd(status: status)
        }
        selfInstance = self
        
        pomoTimer.pause()
        pomoTimer.saveToUserDefaults()
    }

    
    var body: some View {
        GeometryReader { metrics in
            TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
                VStack {
                    HStack {
                        Spacer()
                        MenuButton(pomoTimer: pomoTimer)
                            .padding(.horizontal)
                            .padding(.top)
                            .foregroundColor(.black)
                            .hidden()
                    }
                    Spacer()
                    TimerDisplay(pomoTimer: pomoTimer)
                    Spacer()
                    ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                        .frame(maxHeight: 130)
                    Spacer()
                    ButtonCluster(pomoTimer: pomoTimer, metrics: metrics)
                    Spacer()
                }
                .background(pomoTimer.isPaused ? Color("BackgroundStopped") : getColorForStatus(pomoTimer.getStatus(atDate: context.date)))
                .animation(.easeInOut(duration: 0.3), value: pomoTimer.isPaused)
                .animation(.easeInOut(duration: 0.3), value: getColorForStatus(pomoTimer.getStatus(atDate: context.date)))
                .onAppear {
                    getNotificationPermissions()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        print("\nActive")
                        pomoTimer.restoreFromUserDefaults()
                        cancelPendingNotifications()
                        haptics.prepareHaptics()
                    } else if newPhase == .inactive {
                        print("\nInactive")
                        pomoTimer.saveToUserDefaults()
                        setupNotifications(pomoTimer)
                    }
                }
            }
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
    
    
    private func getColorForStatus(_ status: PomoStatus) -> Color {
        switch status {
        case .work:
            return Color("BackgroundWork")
        case .rest:
            return Color("BackgroundRest")
        case .longBreak:
            return Color("BackgroundLongBreak")
        case .end:
            return Color("BackgroundLongBreak")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
