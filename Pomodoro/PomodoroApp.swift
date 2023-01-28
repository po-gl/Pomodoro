//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI
import BackgroundTasks

@main
struct PomodoroApp: App {
    
    init() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.po-gl.Pomodoro.LiveActivityRefresh", using: nil) { task in
            handleAppRefresh(task: task as! BGProcessingTask)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
