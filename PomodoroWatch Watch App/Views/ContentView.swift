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
        VStack {
            TimerDisplay(pomoTimer: pomoTimer)
            Spacer()
            ButtonCluster(pomoTimer: pomoTimer)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
