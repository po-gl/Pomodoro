//
//  CompletedMiniChart.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/12/24.
//

import SwiftUI
import Charts

@available(iOS 17, *)
struct CompletedMiniChart: View {
    @Environment(\.managedObjectContext) var viewContext

    let width = 8.0
    let radius = 10.0

    @FetchRequest(fetchRequest: TasksData.latestTask)
    var latestTaskResults: FetchedResults<TaskNote>

    var latestTask: TaskNote? {
        latestTaskResults.first
    }

    var completedTasksByDay: [(key: Date, value: (count: Int, placeholder: Bool))] {
        guard let latestTask, let timestamp = latestTask.timestamp else { return [] }
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: timestamp.startOfWeek...timestamp.endOfWeek))
        guard let tasks else { return [] }
        
        var tasksByDay: [Date: (count: Int, placeholder: Bool)] = [:]
        tasks.forEach {
            guard let timestamp = $0.timestamp else { return }
            let startOfDay = timestamp.startOfDay
            if $0.completed {
                tasksByDay[startOfDay, default: (0, false)].count += 1
            }
        }
        // Add placeholder data
        for day in stride(from: timestamp.startOfWeek, to: timestamp.endOfWeek, by: 3600 * 24) {
            if !tasksByDay.contains(where: { $0.key == day }) {
                tasksByDay[day, default: (count: 0, placeholder: true)].placeholder = true
            }
        }
        return tasksByDay.sorted { $0.key < $1.key }
    }

    var maxCompletedValue: Int {
        completedTasksByDay.max { $0.value.count < $1.value.count }?.value.count ?? 4
    }
    
    var body: some View {
        Chart {
            ForEach(completedTasksByDay, id: \.key) { date, value in
                if !value.placeholder {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Completed Tasks", value.count),
                        width: .fixed(width)
                    )
                    .foregroundStyle(PomoStatus.end.gradient(startPoint: .top, endPoint: .bottom))
                    .cornerRadius(radius)
                } else {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Placeholder", 0.5),
                        width: .fixed(width)
                    )
                    .foregroundStyle(disabledGradient(startPoint: .top, endPoint: .bottom))
                    .cornerRadius(radius)
                    .opacity(0.5)
                }
            }
        }
        .chartXScale(domain: (latestTask?.timestamp?.startOfWeek ?? Date.now.startOfWeek)...(latestTask?.timestamp?.endOfWeek ?? Date.now.endOfWeek))
        .chartXVisibleDomain(length: 3600 * 24 * 7 + 1)
        .chartXAxis {
            AxisMarks(position: .top, values: .stride(by: .day, count: 1)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .offset(y: -2)
            }
        }
        .chartYScale(domain: 0...maxCompletedValue + 1)
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(dash: [1.0, 4.0]))
            }
        }
        .transaction {
            $0.animation = nil
        }
    }
}

@available(iOS 17, *)
#Preview {
    CompletedMiniChart()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
