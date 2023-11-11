//
//  MainPage.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/11/23.
//

import SwiftUI

struct MainPage: View {
    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject var pomoTimer: PomoTimer
    @State var taskFromAdder = DraggableTask()

    var body: some View {
        ZStack {
            TopButton(destination: {
                TaskList()
            })
            .zIndex(1)

            ZStack {
                Background()
                    .animation(.default, value: pomoTimer.isPaused)

                TaskAdderView(taskFromAdder: $taskFromAdder)
                    .zIndex(1)

                mainStack
            }
            .animation(.easeInOut(duration: 0.3), value: pomoTimer.isPaused)
            .avoidKeyboard()
        }
    }

    @ViewBuilder private var mainStack: some View {
        GeometryReader { proxy in
            VStack {
                TimerDisplay()
                    .padding(.top, 50)

                Spacer()

                ZStack {
                    ProgressBar(metrics: proxy, taskFromAdder: $taskFromAdder)
                        .frame(maxHeight: 130)
                    BuddyView(metrics: proxy)
                        .offset(y: -7)
                        .brightness(colorScheme == .dark ? 0.0 : 0.1)
                }
                HStack {
                    Spacer()
                    PomoStepper()
                        .offset(y: -20)
                        .padding(.trailing, 20)
                }
                .padding(.bottom, 20)

                ButtonCluster()
                    .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}
