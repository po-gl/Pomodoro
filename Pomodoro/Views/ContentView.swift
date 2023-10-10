//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import CoreHaptics
import WidgetKit
import WatchConnectivity
import Combine

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager
    
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var taskFromAdder = DraggableTask()
    
    @State var didReceiveSyncFromWatchConnection = false
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            EndTimerHandler.shared.handle(status: status)
        }
        pomoTimer.pause()
        pomoTimer.restoreFromUserDefaults()
    }
    
    var body: some View {
        NavigationStack {
            MainPage()
                .reverseStatusBarColor()
                .ignoresSafeArea()
                .onAppear {
                    getNotificationPermissions()
                    viewContext.undoManager = undoManager
                }
            
                .onChange(of: scenePhase) { newPhase in
                    print("Phase \(newPhase)")
                    if newPhase == .active {
                        pomoTimer.restoreFromUserDefaults()
                        cancelPendingNotifications()
                        Haptics.shared.prepareHaptics()
                        setupWatchConnection()
                    } else if newPhase == .inactive || newPhase == .background {
                        pomoTimer.saveToUserDefaults()
                        WidgetCenter.shared.reloadAllTimelines()
                        if !didReceiveSyncFromWatchConnection {
                            Task { await setupNotifications(pomoTimer) }
                        }
                    }
                }
            
                .onChange(of: pomoTimer.isPaused) { _ in
                    WidgetCenter.shared.reloadAllTimelines()
                    let wcSent = updateWatchConnection(pomoTimer)
                    didReceiveSyncFromWatchConnection = !wcSent
                }
            
                .onReceive(Publishers.wcSessionDataDidFlow) { timer in
                    if let timer {
                        print("iOS received pomoTimer.pomoCount=\(timer.pomoCount) isPaused=\(timer.isPaused)")
                        pomoTimer.sync(with: timer)
                        pomoTimer.saveToUserDefaults()
                        didReceiveSyncFromWatchConnection = true
                    }
                }
            
                .onOpenURL { url in
                    if url.absoluteString == "com.po-gl.stop" {
                        pomoTimer.pause()
                        pomoTimer.saveToUserDefaults()
                    }
                }
        }
        .navigationViewStyle(.stack)
        .tint(Color("NavigationAccent"))
    }
    
    
    @ViewBuilder
    private func MainPage() -> some View {
        ZStack {
            TopButton(destination: {
                TaskList();
            }, pomoTimer: pomoTimer)
                .zIndex(1)
            
            ZStack {
                Background(pomoTimer: pomoTimer)
                    .animation(.default, value: pomoTimer.isPaused)
                
                TaskAdderView(taskFromAdder: $taskFromAdder)
                    .zIndex(1)
                
                
                MainStack()
            }
            .animation(.easeInOut(duration: 0.3), value: pomoTimer.isPaused)
            .avoidKeyboard()
        }
    }
    
    
    @ViewBuilder
    private func MainStack() -> some View {
        GeometryReader { proxy in
            VStack {
                TimerDisplay(pomoTimer: pomoTimer)
                    .padding(.top, 50)
                
                Spacer()
                
                ZStack {
                    ProgressBar(pomoTimer: pomoTimer, metrics: proxy,
                                taskFromAdder: $taskFromAdder)
                    .frame(maxHeight: 130)
                    BuddyView(pomoTimer: pomoTimer, metrics: proxy)
                        .offset(y: -7)
                        .brightness(colorScheme == .dark ? 0.0 : 0.1)
                }
                HStack {
                    Spacer()
                    PomoStepper(pomoTimer: pomoTimer)
                        .offset(y: -20)
                        .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
                
                ButtonCluster(pomoTimer: pomoTimer)
                    .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 14 Pro", "iPhone 13 mini"], id: \.self) { device in
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
        }
    }
}
