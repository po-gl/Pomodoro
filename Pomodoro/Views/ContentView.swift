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
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var buddyOffset: Double = 0
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            EndTimerHandler.shared.handle(status: status)
        }
        pomoTimer.pause()
        pomoTimer.restoreFromUserDefaults()
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
                    EndTimerHandler.shared.haptics.prepareHaptics()
                } else if newPhase == .inactive {
                    pomoTimer.saveToUserDefaults()
                    setupNotifications(pomoTimer)
                }
            }
            .onOpenURL { url in
                if url.absoluteString == "com.po-gl.stop" {
                    pomoTimer.pause()
                    pomoTimer.saveToUserDefaults()
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
                    VStack {
                        ZStack {
                            ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                                .frame(maxHeight: 130)
                            BuddyView(pomoTimer: pomoTimer)
                                .brightness(-0.1)
                                .frame(width: 20, height: 20)
                                .offset(x: buddyOffset, y: -8)
                                .onAppear {
                                    buddyOffset = Double.random(in: -60...100)
                                }
                        }
                        HStack {
                            Spacer()
                            PomoStepper(pomoTimer: pomoTimer)
                                .offset(y: -20)
                                .padding(.trailing, 20)
                        }
                    }
                    Spacer()
                    ButtonCluster(pomoTimer: pomoTimer)
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: pomoTimer.isPaused)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
