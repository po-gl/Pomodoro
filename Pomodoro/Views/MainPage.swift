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
    @State var metalDragOffset = CGFloat.zero

    var body: some View {
        ZStack {
            Background(pickOffset: dragOffset, metalPickOffset: metalDragOffset)
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
            let isSmallDevice = Device.isSmall(geometry: proxy)

            VStack {
                TimerDisplay()
                    .padding(.top, isSmallDevice ? 5 : 30)
                    .verticalOffsetEffect(for: dragOffset, .spring, factor: 0.15)

                Color.clear.contentShape(Rectangle())
                    .verticalDragGesture(offset: $dragOffset,
                                         metalOffset:$metalDragOffset,
                                         clampedTo: -20..<120,
                                         onStart: {
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

                PomoStepper()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding([.trailing, .top], 20)
                    .padding(.bottom, isSmallDevice ? 20 : 30)
                    .verticalOffsetEffect(for: dragOffset, .bouncy, factor: 0.8)

                ButtonCluster()
                    .padding(.bottom, isSmallDevice ? 10 : 30)
                    .verticalOffsetEffect(for: dragOffset, .spring, factor: 0.7)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainPage()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(
            PomoTimer(context: PersistenceController.preview.container.viewContext) { status in
                EndTimerHandler.shared.handle(status: status)
            }
        )
        .environmentObject(TasksOnBar.shared)
}
