//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import CoreHaptics
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var pomoTimer: PomoTimer
    
    @StateObject var taskNotes = TaskNotes()
    
    @State var buddyOffset: Double = 0
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            EndTimerHandler.shared.handle(status: status)
        }
        pomoTimer.pause()
        pomoTimer.restoreFromUserDefaults()
    }

    
    var body: some View {
        MainPage()
            .reverseStatusBarColor()
            .ignoresSafeArea()
            .onAppear {
                getNotificationPermissions()
            }
        
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    pomoTimer.restoreFromUserDefaults()
                    taskNotes.restoreFromUserDefaults()
                    cancelPendingNotifications()
                    EndTimerHandler.shared.haptics.prepareHaptics()
                } else if newPhase == .inactive {
                    pomoTimer.saveToUserDefaults()
                    taskNotes.saveToUserDefaults()
                    setupNotifications(pomoTimer)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        
            .onChange(of: pomoTimer.isPaused) { _ in
                print("Reload")
                WidgetCenter.shared.reloadAllTimelines()
            }
        
            .onOpenURL { url in
                if url.absoluteString == "com.po-gl.stop" {
                    pomoTimer.pause()
                    pomoTimer.saveToUserDefaults()
                }
            }
    }
    
    
    @ViewBuilder
    private func MainPage() -> some View {
        ZStack {
            Background(pomoTimer: pomoTimer)
            
            TaskAdderView(taskNotes: taskNotes)
                .opacity(pomoTimer.isPaused ? 1.0 : 0.7)
                .zIndex(1)
            
            MainStack()
        }
        .animation(.easeInOut(duration: 0.3), value: pomoTimer.isPaused)
    }
    
    
    @ViewBuilder
    private func MainStack() -> some View {
        GeometryReader { proxy in
            VStack {
                TimerDisplay(pomoTimer: pomoTimer)
                    .padding(.top, 50)
                
                Spacer()
                
                ZStack {
                    ProgressBar(pomoTimer: pomoTimer,
                                metrics: proxy,
                                taskNotes: taskNotes)
                    .frame(maxHeight: 130)
                    BuddyView(pomoTimer: pomoTimer)
                        .frame(width: 20, height: 20)
                        .offset(x: buddyOffset, y: -8)
                        .onAppear { buddyOffset = Double.random(in: -120...100) }
                        .brightness(-0.1)
                }
                HStack {
                    Spacer()
                    PomoStepper(pomoTimer: pomoTimer)
                        .offset(y: -20)
                        .padding(.trailing, 20)
                }
                .padding(.bottom, 30)
                
                ButtonCluster(pomoTimer: pomoTimer)
                    .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
