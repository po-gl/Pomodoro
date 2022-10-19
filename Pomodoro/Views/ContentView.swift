//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var sequenceTimer: SequenceTimer
    @State var timeIntervals: [TimeInterval]
    
    @State var backgroundActiveColor: Color
    
    
    init() {
//        let localtimeIntervals = [25*60.0, 5*60.0]
        let localtimeIntervals = [4.0, 5.0]
        let localsequenceTimer = SequenceTimer(sequenceOfIntervals: localtimeIntervals)
        self.timeIntervals = localtimeIntervals
        self.sequenceTimer = localsequenceTimer
        
        self.backgroundActiveColor = Color("BackgroundWork")
        
        self.sequenceTimer.restoreFromUserDefaults()
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
                timerDisplay()
                Spacer()
                ProgressBar(sequenceTimer: sequenceTimer,
                            timeIntervals: $timeIntervals,
                            metrics: metrics)
                    .frame(maxHeight: 130)
                Spacer()
                buttonCluster()
                Spacer()
            }
            .background(sequenceTimer.isPaused ? Color("BackgroundStopped") : backgroundActiveColor)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification), perform: {_ in
                sequenceTimer.saveToUserDefaults()
            })
        }
    }
    
    
    func handleTimerEnd() {
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundActiveColor = sequenceTimer.currentIndex % 2 == 0 ? Color("BackgroundWork") : Color("BackgroundRest")
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
    

    func timerDisplay() -> some View {
        VStack(alignment: .leading) {
            Text("Timer: \(sequenceTimer.currentIndex+1)")
                .font(.system(size: 30))
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
                .onChange(of: sequenceTimer.currentIndex) { _ in
                    handleTimerEnd()
                }
            Text("\(sequenceTimer.timeRemaining.timerFormatted())")
                .font(.system(size: 70))
                .fontWeight(.light)
                .monospacedDigit()
                .shadow(radius: 20)
        }
    }
    
    
    func buttonCluster() -> some View {
        return HStack {
            Spacer()
            Button(action: {
                sequenceTimer.reset()
            }, label: {
                Text("Reset")
                    .font(.system(size: 20).monospaced())
                    .foregroundColor(sequenceTimer.isPaused ? .orange : .gray)
            })
            .disabled(!sequenceTimer.isPaused)
            Spacer()

            Button(action: {
                withAnimation(.easeIn(duration: 0.2)){
                    sequenceTimer.toggle()
                }
            }, label: {
                Text(sequenceTimer.isPaused ? "Start" : "Stop")
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
