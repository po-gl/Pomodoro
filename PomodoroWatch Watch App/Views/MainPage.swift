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
    
    @State var buddyOffset: Double = 0
    
    var body: some View {
        VStack {
            GeometryReader { metrics in
                VStack {
                    TimerDisplay(pomoTimer: pomoTimer)
                    Spacer()
                    ZStack {
                        ProgressBar(pomoTimer: pomoTimer, metrics: metrics)
                        BuddyView(pomoTimer: pomoTimer)
                            .frame(width: 20, height: 20)
                            .offset(x: buddyOffset, y: -6)
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
        .onAppear {
            buddyOffset = Double.random(in: -40...30)
        }
    }
}
