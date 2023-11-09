//
//  MainPage.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/28/22.
//

import SwiftUI
import WidgetKit

struct MainPage: View {
    @EnvironmentObject var pomoTimer: PomoTimer

    var body: some View {
        GeometryReader { metrics in
            VStack {
                Group {
                    TimerDisplay(metrics: metrics)
                    Spacer()
                    ZStack {
                        ProgressBar(metrics: metrics)
                        BuddyView(metrics: metrics)
                            .offset(y: -6)
                    }
                }
                .offset(y: -15)

                Spacer()
                ButtonCluster()
                    .padding([.bottom, .horizontal])
            }
            .ignoresSafeArea()
            .padding(.top, 1)
        }
    }
}
