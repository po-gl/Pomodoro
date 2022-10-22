//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var backgroundActiveColor = Color("BackgroundWork")
    
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: 30.0)
        pomoTimer.restoreFromUserDefaults()
    }

    
    var body: some View {
        GeometryReader { metrics in
            VStack {
                HStack {
                    Spacer()
                    menuButton()
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
                ButtonCluster(pomoTimer: pomoTimer)
                Spacer()
            }
            .background(pomoTimer.isPaused ? Color("BackgroundStopped") : backgroundActiveColor)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification), perform: {_ in
                pomoTimer.saveToUserDefaults()
            })
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
        
        // Asking permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set on permissions!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        
        // Vibration?
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
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

    
    func menuButton() -> some View {
        return Menu {
            Button(action: {}) {
                Label("Manage Timers", systemImage: "clock.arrow.2.circlepath")
            }
            Button(action: {}) {
                Label("About", systemImage: "sparkles")
                    .symbolRenderingMode(.multicolor)
            }
        }
        label: {
            Button(action: {}) {
                ZStack {
                    Circle()
                        .frame(maxWidth: 40)
                        .foregroundColor(.white)
                        .opacity(0.0)
                    Image(systemName: "cloud.rain.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 20))
                        .shadow(radius: 20)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
