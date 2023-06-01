//
//  AddTaskButton.swift
//  Pomodoro
//
//  Created by Porter Glines on 5/31/23.
//

import SwiftUI

struct AddTaskButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    var scrollProxy: ScrollViewProxy
    var scrollToID: UUID
    
    var body: some View {
        Button(action: {
            TasksData.addTask("", context: viewContext)
            withAnimation { scrollProxy.scrollTo(scrollToID) }
        } ) {
            Label("New Task", systemImage: "plus.circle.fill")
                .labelStyle(.titleAndIcon)
        }.tint(Color("AccentColor"))
    }
}
