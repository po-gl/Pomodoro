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
                .animation(.easeInOut(duration: 0.3), value: getColorForStatus(pomoTimer.getStatus(atDate: context.date)))
                .onAppear {
                    getNotificationPermissions()
                    haptics.prepareHaptics()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        print("\nActive")
                        pomoTimer.restoreFromUserDefaults()
                    } else if newPhase == .inactive {
                        print("\nInactive")
                        print(self)
                        pomoTimer.saveToUserDefaults()
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
        
        // Notification
        let content = UNMutableNotificationContent()
        content.title = "Time is up."
        content.subtitle = "\(Date().formatted(date: .abbreviated, time: .shortened)) it happens to everyone"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
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
