//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI

@main
struct PomodoroApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
