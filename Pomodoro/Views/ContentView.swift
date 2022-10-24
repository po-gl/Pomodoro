//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import CoreHaptics

struct ContentView: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var backgroundActiveColor = Color("BackgroundWork")
    
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime)
        pomoTimer.restoreFromUserDefaults()
    }

    
    var body: some View {
        GeometryReader { metrics in
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
            .background(pomoTimer.isPaused ? Color("BackgroundStopped") : backgroundActiveColor)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification), perform: {_ in
//                pomoTimer.saveToUserDefaults()
            })
            .onAppear {
                getNotificationPermissions()
                prepareHaptics(engine: &engine)
            }
            .onChange(of: pomoTimer.status) { _ in
                handleTimerEnd()
            }
        }
    }
    
    
    func handleTimerEnd() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch pomoTimer.status {
            case .work:
                backgroundActiveColor = Color("BackgroundWork")
            case .rest:
                backgroundActiveColor = Color("BackgroundRest")
            case .longBreak:
                backgroundActiveColor = Color("BackgroundLongBreak")
            }
        }
        
        if !pomoTimer.isPaused {
            switch pomoTimer.status {
            case .work:
                workHaptic(engine: engine)
            case .rest:
                restHaptic(engine: engine)
            case .longBreak:
                breakHaptic(engine: engine)
            }
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
