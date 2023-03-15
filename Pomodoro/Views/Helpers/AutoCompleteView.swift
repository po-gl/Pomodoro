//
//  AutoCompleteView.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/14/23.
//

import SwiftUI

struct AutoCompleteView: View {
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(sortDescriptors: [SortDescriptor(\TaskNote.order), SortDescriptor(\TaskNote.timestamp)], predicate: NSPredicate(format: "timestamp >= %@ && timestamp <= %@", Calendar.current.startOfDay(for: Date()) as CVarArg, Calendar.current.startOfDay(for: Date() + 86400) as CVarArg))
    private var todaysTasks: FetchedResults<TaskNote>
    
    @Binding var text: String
    
    
    var body: some View {
        let itemsToShow = 3
        VStack {
            Spacer()
            VStack (alignment: .leading, spacing: 8) {
                let tasks = tasksStartingWith(text)
                let tasksToShow = tasks.count >= itemsToShow ? tasks[..<itemsToShow].reversed() : tasks[0...].reversed()
                ForEach(tasksToShow) { taskItem in
                    Row(taskItem.text!)
                }
            }
        }
        .frame(width: 280, height: 120)
    }
    
    
    @ViewBuilder
    private func Row(_ rowText: String) -> some View {
        HStack {
            Button {
                text = rowText
            } label: {
                Text(rowText)
                    .lineLimit(1)
                    .font(.system(size: 16))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 10)
                    .opacity(0.7)
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("BackgroundStopped"))
                    .brightness(colorScheme == .dark ? 0.13 : -0.03)
                    .saturation(colorScheme == .dark ? 0.0 : 1.2)
            }
            .tint(.primary)
            Spacer()
        }
    }
    
    
    private func tasksStartingWith(_ text: String) -> [TaskNote] {
        return todaysTasks.filter { $0.text!.starts(with: text) && $0.text! != text }
    }
}


