//
//  AppFeaturesView.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/1/24.
//

import SwiftUI

struct AppFeaturesView: View {
    @Environment(\.colorScheme) var colorScheme

    @StateObject var pomoTimer = PomoTimer()
    @StateObject var tasksOnBar = TasksOnBar()
    @State var draggableTaskStub = DraggableTask()

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    ProgressBar(metrics: geometry, taskFromAdder: $draggableTaskStub)
                        .frame(maxHeight: 60)
                    BuddyView(metrics: geometry)
                        .offset(y: -7)
                        .brightness(colorScheme == .dark ? 0.0 : 0.1)
                }
                .padding(.top, 170)
                .allowsHitTesting(false)

                Divider()
                    .padding(.vertical, 15)
                
                BulletedList(textList: [
                    "Drag tasks to the progress bar, assigning them to Pomodoros.",
                    "Track the progress of the timer in a _LiveActivity_ on your lockscreen, in _StandBy_ mode, or in the _DynamicIsland_.",
                    "Manage and reflect on tasks in the task list.",
                    "See usage trends in the charts tab.",
                ], withIcons: [
                    AnyView(touchCircle),
                    AnyView(pomoTimerIcon),
                    AnyView(pomoCheck),
                    AnyView(pomoChartIcon),
                ], spacing: 25)
                .frame(maxWidth: 400)
                .padding(.horizontal, 20)
                .font(.body)
                .fontWeight(.regular)
                
                Spacer()
            }
            .onAppear {
                tasksOnBar.setTaskAmount(for: pomoTimer)
                tasksOnBar.addTask("Improve focus", index: 0, context: nil)
                tasksOnBar.addTask("Alleviate stress", index: 2, context: nil)
                tasksOnBar.addTask("Relax", index: 4, context: nil)
                pomoTimer.setPercentage(to: 0.43)
                pomoTimer.unpause()
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .environmentObject(pomoTimer)
        .environmentObject(tasksOnBar)
        .environment(\.isOnBoarding, true)
    }

    @ViewBuilder var touchCircle: some View {
        let width: Double = 22
        let strokeWidth: Double = 1.2
        let gap: Double = 8
        Circle()
            .strokeBorder(style: StrokeStyle(lineWidth: strokeWidth))
            .frame(width: width, height: width)
            .background(
                Circle()
                    .opacity(0.25)
                    .frame(width: width - gap - strokeWidth)
            )
            .overlay(
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: strokeWidth))
                    .frame(width: width - gap)
            )
            .opacity(0.5)
            .offset(x: 0, y: 7)
    }

    @ViewBuilder var pomoCheck: some View {
        Image(.pomoChecklist)
            .imageScale(.large)
            .opacity(0.5)
            .offset(x: -2, y: 4)
    }

    @ViewBuilder var pomoTimerIcon: some View {
        Image(.pomoTimer)
            .imageScale(.large)
            .fontWeight(.medium)
            .opacity(0.5)
            .offset(x: 2, y: 3)
    }

    @ViewBuilder var pomoChartIcon: some View {
        Image(.pomoChart)
            .imageScale(.large)
            .fontWeight(.medium)
            .opacity(0.5)
            .offset(x: 2, y: 3)
    }
}

#Preview("Base View") {
    AppFeaturesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("From Sheet") {
    Text("Base")
        .sheet(isPresented: Binding(get: { true }, set: { _ in } )) {
            ZStack {
                OnBoardViewBackground(color: .barRest)
                    .ignoresSafeArea()
                AppFeaturesView()
                    .presentationDragIndicator(.visible)
                    .padding(.top, 60)
            }
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
