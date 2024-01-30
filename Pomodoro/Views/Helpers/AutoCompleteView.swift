//
//  AutoCompleteView.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/14/23.
//

import SwiftUI

struct AutoCompleteView: View {
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(sortDescriptors: [SortDescriptor(\TaskNote.order),
                                    SortDescriptor(\TaskNote.timestamp)],
                  predicate: NSPredicate(format: "timestamp >= %@ && timestamp <= %@",
                                         Calendar.current.startOfDay(for: Date()) as CVarArg,
                                         Calendar.current.startOfDay(for: Date() + 86400) as CVarArg))
    private var todaysTasks: FetchedResults<TaskNote>

    @Binding var text: String
    let itemsToShow = 5

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 11) {
                let tasks = tasksStartingWith(text)
                let tasksToShow = tasks.count >= itemsToShow ? tasks[..<itemsToShow].reversed() : tasks[0...].reversed()
                ForEach(tasksToShow) { taskItem in
                    row(taskItem.text!)
                }
            }
        }
        .frame(width: 280, height: 200)
    }

    @ViewBuilder
    private func row(_ rowText: String) -> some View {
        HStack {
            Button {
                text = rowText
            } label: {
                Text(rowText)
                    .lineLimit(1)
                    .font(.system(.callout, design: .monospaced))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .opacity(0.7)
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.backgroundStopped)
                    .brightness(colorScheme == .dark ? 0.13 : -0.03)
                    .saturation(colorScheme == .dark ? 0.0 : 1.2)
            }
            .tint(.primary)
            Spacer()
        }
    }

    private func tasksStartingWith(_ text: String) -> [TaskNote] {
        guard !text.isEmpty else { return todaysTasks.filter { !$0.completed } }

        let text = text.lowercased()
        return todaysTasks.filter {
            let taskText = $0.text!.lowercased()
            return taskText.contains(text) && taskText != text
        }
    }
}
