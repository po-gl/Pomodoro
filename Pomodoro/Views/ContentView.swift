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
        self.pomoTimer = PomoTimer(pomos: 2, longBreak: 30.0)
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
                ProgressBar(pomoTimer: pomoTimer,
                            metrics: metrics)
                    .frame(maxHeight: 130)
                Spacer()
                buttonCluster()
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
            case "Work":
                backgroundActiveColor = Color("BackgroundWork")
            case "Rest":
                backgroundActiveColor = Color("BackgroundRest")
            case "Long Break":
                backgroundActiveColor = Color("BackgroundLongBreak")
            default:
                backgroundActiveColor = Color("BackgroundRest")
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
    

    func buttonCluster() -> some View {
        return HStack {
            Spacer()
            Button(action: {
                pomoTimer.reset()
            }, label: {
                Text("Reset")
                    .font(.system(size: 20).monospaced())
                    .foregroundColor(pomoTimer.isPaused ? .orange : .gray)
            })
            .disabled(!pomoTimer.isPaused)
            Spacer()

            Button(action: {
                withAnimation(.easeIn(duration: 0.2)){
                    pomoTimer.toggle()
                }
            }, label: {
                Text(pomoTimer.isPaused ? "Start" : "Stop")
                    .font(.system(size: 30).monospaced())
            })
            Spacer()
        }
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
