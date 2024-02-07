//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import Combine

struct ContentView: View {
    @AppStorage("shouldOnBoard", store: UserDefaults.pomo) var shouldOnBoard = true

    @ObservedObject var errors = Errors.shared

    @State var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MainPage()
                .reverseStatusBarColor()
                .toasts()
                .tabItem { Label { Text("Pomodoro") } icon: { Image(.pomoTimer) } }
                .tag(0)
            TaskList()
                .toasts(bottomPadding: 50)
                .tabItem { Label { Text("Tasks") } icon: { Image(.pomoChecklist) } }
                .tag(1)
                .badge(errors.coreDataError != nil ? "!" : nil)
            ChartsPage()
                .toasts()
                .tabItem { Label("Charts", systemImage: "chart.bar.xaxis")}
                .tag(2)
            SettingsPage()
                .toasts()
                .tabItem { Label { Text("Settings") } icon: { Image(.pomoGear) } }
                .tag(3)
        }
        .onReceive(Publishers.selectFirstTab) { _ in
            selectedTab = 0
        }

        .sheet(isPresented: $shouldOnBoard) {
            OnBoardView()
                .presentationDragIndicator(.visible)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 15 Pro", "iPhone 13 mini"], id: \.self) { device in
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
                .environmentObject(
                    PomoTimer(context: PersistenceController.preview.container.viewContext) { status in
                        EndTimerHandler.shared.handle(status: status)
                    }
                )
                .environmentObject(TasksOnBar.shared)
        }
    }
}
