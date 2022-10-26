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
        
        pomoTimer.saveToUserDefaults()
    }

    
    var body: some View {
        GeometryReader { metrics in
            TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
                VStack {
                    HStack {
                        Spacer()
                        MenuButton()
                            .padding(.horizontal)
                            .padding(.top)
                            .foregroundColor(.black)
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
    
    
    func handleTimerEnd(status: PomoStatus) {
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
    
    
    func getColorForStatus(_ status: PomoStatus) -> Color {
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
    
    
    func getNotificationPermissions() {
        // Asking permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, error in
            if success {
                print("All set on permissions!")
            } else if let error = error {
                print("There was an error requesting permissions: \(error.localizedDescription)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
