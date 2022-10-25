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
            }
        }
    }
    
    var body: some View {
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("\nActive")
                pomoTimer.restoreFromUserDefaults()
            } else if newPhase == .inactive {
                print("\nInactive")
                pomoTimer.saveToUserDefaults()
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
