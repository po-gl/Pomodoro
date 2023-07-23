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
        GeometryReader { metrics in
            VStack {
                Group {
                    TimerDisplay(pomoTimer: pomoTimer, metrics: metrics)
                    Spacer()
                    ZStack {
                        ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                        BuddyView(pomoTimer: pomoTimer, metrics: metrics)
                            .offset(y: -6)
                    }
                }
                .offset(y: -15)
                
                Spacer()
                ButtonCluster(pomoTimer: pomoTimer)
                    .padding([.bottom, .horizontal])
            }
            .ignoresSafeArea()
            .padding(.top, 1)
        }
    }
}
