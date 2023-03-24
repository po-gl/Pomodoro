//
//  MainPage.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/28/22.
//

import SwiftUI
import WidgetKit

struct MainPage: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        VStack {
            GeometryReader { metrics in
                VStack {
                    TimerDisplay(pomoTimer: pomoTimer)
                    Spacer()
                    ZStack {
                        ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                        BuddyView(pomoTimer: pomoTimer, metrics: metrics)
                            .offset(y: -6)
                    }
                    Spacer()
                    Spacer()
                    ButtonCluster(pomoTimer: pomoTimer)
                        .padding(.bottom)
                }
                .ignoresSafeArea()
                .padding(.top)
            }
        }
    }
}
