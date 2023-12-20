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

    @State var dragOffset = CGFloat.zero

    var body: some View {
        ZStack {
            Background(pickOffset: dragOffset)
                .animation(.default, value: pomoTimer.isPaused)

            TaskAdderView(taskFromAdder: $taskFromAdder)
                .zIndex(1)
                .verticalOffsetEffect(for: dragOffset, .spring, factor: 0.3)

            mainStack
        }
        .animation(.easeInOut(duration: 0.3), value: pomoTimer.isPaused)
        .avoidKeyboard()
        .showTabBar(for: dragOffset - 30)
    }

    @ViewBuilder private var mainStack: some View {
        GeometryReader { proxy in
            VStack {
                TimerDisplay()
                    .padding(.top, 30)
                    .verticalOffsetEffect(for: dragOffset, .spring, factor: 0.15)

                Color.clear.contentShape(Rectangle())
                    .verticalDragGesture(offset: $dragOffset, clampedTo: -20..<80, onStart: {
                        Task { @MainActor in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                            to: nil, from: nil, for: nil)
                        }
                    })

                ZStack {
                    ProgressBar(metrics: proxy, taskFromAdder: $taskFromAdder, peekOffset: dragOffset)
                        .frame(maxHeight: 60)
                    BuddyView(metrics: proxy)
                        .offset(y: -7)
                        .brightness(colorScheme == .dark ? 0.0 : 0.1)
                }
                .verticalOffsetEffect(for: dragOffset, .bouncy)

                HStack {
                    Spacer()
                    PomoStepper()
                        .padding(20)
                }
                .padding(.bottom, 10)
                .verticalOffsetEffect(for: dragOffset, .bouncy)

                ButtonCluster()
                    .padding(.bottom, 30)
                    .verticalOffsetEffect(for: dragOffset, .spring, factor: 0.7)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}
