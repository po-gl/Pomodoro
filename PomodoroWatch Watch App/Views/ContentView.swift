//
//  ContentView.swift
//  PomodoroWatch Watch App
//
//  Created by Porter Glines on 10/23/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MainPage()
            GeometryReader { geometry in
                SettingsPage(geometry: geometry)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PomoTimer())
}
