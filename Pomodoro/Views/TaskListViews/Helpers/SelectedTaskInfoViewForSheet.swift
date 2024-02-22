//
//  SelectedTaskInfoViewForSheet.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/22/24.
//

import SwiftUI

// Properties don't trigger view updates in a sheet closure unless
// used as a binding in the subview
struct SelectedTaskInfoViewForSheet: View {
    @Binding var selectedTask: TaskNote?
    var scrollToOnAppear: String
    var body: some View {
        if let selectedTask {
            TaskInfoView(taskItem: selectedTask, scrollToIdOnAppear: scrollToOnAppear)
        }
    }
}
