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
            basicHaptic()
            TasksData.addTask("", context: viewContext)
            withAnimation { scrollProxy.scrollTo(scrollToID) }
        } ) {
            Text(Image(systemName: "plus.circle.fill"))
            Text("New Task")
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
        }.tint(Color("AccentColor"))
    }
}
