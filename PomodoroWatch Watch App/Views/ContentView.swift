//
//  ContentView.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/23/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    init() {
        pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime)
        pomoTimer.restoreFromUserDefaults()
    }
    
    var body: some View {
        GeometryReader { metrics in
            VStack {
                TimerDisplay(pomoTimer: pomoTimer)
                Spacer()
                ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                Spacer()
                ButtonCluster(pomoTimer: pomoTimer)
                    .padding(.bottom)
            }
            .ignoresSafeArea()
            .padding(.top)
        }
        .onAppear {
        }
        .onChange(of: pomoTimer.status) { _ in
            handleTimerEnd()
        }
    }
    
    
    func handleTimerEnd() {
        if !pomoTimer.isPaused {
            switch pomoTimer.status {
            case .work:
                workHaptic()
            case .rest:
                restHaptic()
            case .longBreak:
                breakHaptic()
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
