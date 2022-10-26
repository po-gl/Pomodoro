//
//  ContentView.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/23/22.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var pomoTimer: PomoTimer
    
    @State var start = Date()
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
            print("Performed action! \(Date()) \(status)")
            switch status {
            case .work:
                workHaptic()
            case .rest:
                restHaptic()
            case .longBreak:
                breakHaptic()
            case .end:
                breakHaptic()
            }
        }
        
        pomoTimer.saveToUserDefaults()
    }
    
    var body: some View {
        TabView {
            mainPage()
            pomoChanger()
        }
    }
    
    
    func mainPage() -> some View {
        VStack {
            GeometryReader { metrics in
                VStack {
                    TimerDisplay(pomoTimer: pomoTimer)
                    Spacer()
                    ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                    Spacer()
                    Spacer()
                    ButtonCluster(pomoTimer: pomoTimer)
                        .padding(.bottom)
                }
                .ignoresSafeArea()
                .padding(.top)
            }
            .onAppear {
                getNotificationPermissions()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    print("\nActive")
                    pomoTimer.restoreFromUserDefaults()
                    cancelPendingNotifications()
                } else if newPhase == .inactive {
                    print("\nInactive")
                    pomoTimer.saveToUserDefaults()
                    setupNotifications(pomoTimer)
                }
            }
        }
    }
    
    
    func pomoChanger() -> some View {
        VStack {
            Spacer()
            VStack(alignment: .center) {
                Text("Pomos")
                    .foregroundColor(Color("BarWork"))
                    .font(.system(size: 26))
                    .fontWeight(.light)
                Divider()
                Text("\(Array(repeating: "🍅", count: pomoTimer.pomoCount).joined(separator: ""))")
                    .font(.system(size: 24))
                    .fontWeight(.regular)
            }
            Spacer()
            HStack {
                Spacer()
                Stepper {
                } onIncrement: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pomoTimer.incrementPomos()
                    }
                } onDecrement: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pomoTimer.decrementPomos()
                    }
                }
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["Apple Watch Series 7 (41mm)", "Apple Watch Series 7 (45mm)"], id: \.self) { deviceName in
            ContentView()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}
