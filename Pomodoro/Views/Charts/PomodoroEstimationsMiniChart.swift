//
//  PomodoroEstimationsMiniChart.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/10/24.
//

import SwiftUI
import Charts

@available(iOS 17, *)
struct PomodoroEstimationsMiniChart: View {
    @Environment(\.managedObjectContext) var viewContext

    let categoryOffset: Int = 1

    @FetchRequest(fetchRequest: TasksData.latestTask)
    var latestTaskResults: FetchedResults<TaskNote>

    var latestTask: TaskNote? {
        latestTaskResults.first
    }

    var taskAverages: [(key: Date, value: (estimation: Double, actual: Double, placeholder: Bool))] {
        guard let latestTask, let timestamp = latestTask.timestamp else { return [] }
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: timestamp.startOfWeek...timestamp.endOfWeek))
        guard let tasks else { return [] }
        
        var tasksByDay: [Date: (estimation: Int, actual: Int, estimationCount: Int, actualCount: Int)] = [:]
        tasks.forEach {
            guard let timestamp = $0.timestamp else { return }
            let startOfDay = timestamp.startOfDay
            if tasksByDay[startOfDay] == nil {
                tasksByDay[startOfDay] = (estimation: 0, actual: 0, estimationCount: 0, actualCount: 0)
            }
            if $0.pomosEstimate > 0 {
                tasksByDay[startOfDay]?.estimation += Int($0.pomosEstimate)
                tasksByDay[startOfDay]?.estimationCount += 1
            }
            if $0.pomosActual > 0 && $0.completed {
                tasksByDay[startOfDay]?.actual += Int($0.pomosActual)
                tasksByDay[startOfDay]?.actualCount += 1
            }
        }
        var taskAverages = tasksByDay.mapValues {
            (
                estimation: Double($0.estimation) / Double($0.estimationCount),
                actual: Double($0.actual) / Double($0.actualCount),
                placeholder: false
            )
        }
        // Add placeholder data
        for day in stride(from: timestamp.startOfWeek, to: timestamp.endOfWeek, by: 3600 * 24) {
            if !taskAverages.contains(where: { $0.key == day }) {
                taskAverages[day, default: (estimation: 0, actual: 0, placeholder: true)].placeholder = true
            }
        }
        return taskAverages.sorted { $0.key < $1.key }
    }

    var body: some View {
        Chart {
            ForEach(taskAverages, id: \.key) { date, value in
                if value.estimation > 0 && value.actual > 0 {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        yStart: .value("Estimation Comparison", value.estimation + Double(categoryOffset)),
                        yEnd: .value("Actual Comparison", value.actual + Double(categoryOffset)),
                        width: .fixed(8)
                    )
                    .foregroundStyle(disabledGradient(startPoint: .bottom, endPoint: .top))
                    .cornerRadius(4.0)
                    .opacity(0.7)
                    .offset(yStart: -2, yEnd: 2)
                    .zIndex(-1)
                }
                if value.estimation > 0 {
                    PointMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Estimation", value.estimation + Double(categoryOffset))
                    )
                    .foregroundStyle(Color.barRest)
                    .symbol(.circle)
                    .symbolSize(64)
                }
                if value.actual > 0 {
                    PointMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Actual", value.actual + Double(categoryOffset))
                    )
                    .foregroundStyle(Color.end)
                    .symbol(.diamond)
                    .symbolSize(64)
                }
                if value.placeholder {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        yStart: .value("Placeholder Start", 1 + Double(categoryOffset)),
                        yEnd: .value("Placeholder End", 5 + Double(categoryOffset)),
                        width: .fixed(7)
                    )
                    .foregroundStyle(.grayedOut)
                    .cornerRadius(4.0)
                    .opacity(0.4)
                    .zIndex(-1)
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
            }
        }
        .chartYScale(domain: 0.0...7.0)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                let valueInt = value.as(Int.self) ?? -1
                if valueInt == 1 || valueInt == 4 {
                    AxisGridLine()
                        .foregroundStyle(.grayedOut)
                } else {
                    AxisGridLine(stroke: StrokeStyle(dash: [1.0, 4.0]))
                        .foregroundStyle(.grayedOut)
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    PomodoroEstimationsMiniChart()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
