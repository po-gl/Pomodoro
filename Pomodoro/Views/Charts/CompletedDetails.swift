//
//  CompletedDetails.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/12/24.
//

import SwiftUI
import Charts
import Algorithms

@available(iOS 17, *)
struct WeeklyCompletedTasks: View {
    @Binding var selection: Date?
    @Binding var lastingSelection: Date?
    @Binding var scrollPosition: Date

    var averageFocused: Bool

    let widthRatio = 0.5
    let radius = 10.0

    @FetchRequest(fetchRequest: TasksData.pastTasksRequest(olderThan: Date.now))
    var allTasks: FetchedResults<TaskNote>

    var completedTasksByDay: [(key: Date, value: Int)] {
        var tasksByDay: [Date: Int] = [:]
        allTasks.forEach {
            guard let timestamp = $0.timestamp else { return }
            let startOfDay = timestamp.startOfDay
            if $0.completed {
                tasksByDay[startOfDay, default: 0] += 1
            }
        }
        return tasksByDay.sorted { $0.key < $1.key }
    }

    var maxCompletedValue: Int {
        // Limit scope to past 30 days
        let maxCompleted = completedTasksByDay
            .suffix { -$0.key.timeIntervalSinceNow < 3600 * 24 * 30 }
            .max { $0.value < $1.value }?.value ?? 0
        return max(maxCompleted, 3)
    }

    var averagesByWeek: [(key: Date, value: Double)] {
        let tasks = completedTasksByDay
        
        var totalsAndDayCounts: [Date: (total: Int, dayCounts: Int)] = [:]
        tasks.forEach {
            let startOfWeek = Calendar.current.startOfWeek(for: $0.key)
            
            totalsAndDayCounts[startOfWeek, default: (0, 0)].total += $0.value
            if totalsAndDayCounts[startOfWeek, default: (0, 0)].dayCounts < 1 {
                let countOfDays = ceil(min(7, Date.now.timeIntervalSince(startOfWeek) / (3600 * 24)))
                totalsAndDayCounts[startOfWeek, default: (0, 0)].dayCounts = Int(countOfDays)
            }
        }
        let averages = totalsAndDayCounts.mapValues {
            guard $0.dayCounts > 0 else { return 0.0 }
            return Double($0.total) / Double($0.dayCounts)
        }
        return averages.sorted { $0.key < $1.key }
    }

    var body: some View {
        Chart {
            ForEach(completedTasksByDay, id: \.key) { date, value in
                BarMark(
                    x: .value("Date", date, unit: .day),
                    y: .value("Completed Tasks", value),
                    width: .ratio(widthRatio)
                )
                .foregroundStyle(barStyle(isFocused: !averageFocused))
                .cornerRadius(radius)
            }
            if averageFocused {
                ForEach(averagesByWeek, id: \.key) { average in
                    RuleMark(
                        xStart: .value("Start of Average", average.key),
                        xEnd: .value("End of Average", average.key.addingTimeInterval(3600 * 24 * 7)),
                        y: .value("Weekly Average", average.value)
                    )
                    .foregroundStyle(.barLongBreak)
                    .annotation(
                        position: .top,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) { context in
                        let width = context.targetSize.width
                        Text(String(format: "%.1f", average.value))
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 2)
                            .foregroundStyle(.black)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.barLongBreak))
                            .padding(.leading, 3)
                            .frame(minWidth: width > 0 ? width : 0, alignment: .leading)
                    }
                }
            }
            if let selection {
                RuleMark(
                    x: .value("Selected", selection, unit: .day)
                )
                .foregroundStyle(.barWork)
                .opacity(0.6)
                .zIndex(-1)
            }
            if let lastingSelection {
                RuleMark(
                    x: .value("Lasting Selection", lastingSelection, unit: .day)
                )
                .foregroundStyle(.grayedOut)
                .zIndex(-2)
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartScrollTargetBehavior(
            .valueAligned(
                matching: DateComponents(hour: 0),
                majorAlignment: .matching(DateComponents(weekday: 1))
            )
        )
        // Scrolling with a binding causes an unacceptable amount of lag
        // this is likely a bug with Charts that occurs with all but the lightest Sequences as data
//        .chartScrollPosition(x: $scrollPosition)
        .chartScrollPosition(initialX: Date.now.startOfWeek)

        .chartXScale(domain: (allTasks.last?.timestamp?.startOfWeek ?? Date.now.startOfWeek)...(allTasks.first?.timestamp?.endOfWeek ?? Date.now.endOfWeek))
        .chartXVisibleDomain(length: 3600 * 24 * 7 + 1)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
            // This top mark is only necessary while scrollPosition is not viable
            AxisMarks(position: .top, values: .stride(by: .day)) { value in
                if let date = value.as(Date.self), date == date.startOfWeek {
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .chartYScale(domain: 0...maxCompletedValue + 1)
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(collisionResolution: .greedy(priority: 0.0)) {
                    Text("\(value.as(Int.self) ?? 0)")
                        .monospacedDigit()
                }
            }
        }

        .aspectRatio(1.3, contentMode: .fit)
        .chartXSelection(value: $selection)
        .onChange(of: selection) {
            if selection != nil {
                lastingSelection = selection
            }
        }
        .transaction {
            $0.animation = nil
        }
    }

    func barStyle(isFocused: Bool) -> LinearGradient {
        if isFocused {
            PomoStatus.end.gradient(startPoint: .top, endPoint: .bottom)
        } else {
            disabledGradient(startPoint: .top, endPoint: .bottom)
        }
    }
}

@available(iOS 17, *)
struct CompletedDetails: View {
    @Environment(\.managedObjectContext) var viewContext

    @State var averageFocused: Bool = false

    @State var selection: Date?
    @State var lastingSelection: Date?
    @State var selectionTasks: [TaskNote]?

    @State var scrollPosition = Date.now.startOfDay
    @State var visibleDate = Date.now

    @FetchRequest(fetchRequest: TasksData.pastTasksRequest(olderThan: Date.now))
    var allTasks: FetchedResults<TaskNote>

    var visibleRange: ClosedRange<Date> {
        let startOfWeek = Calendar.current.startOfWeek(for: visibleDate)
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)! - 1.0
        return startOfWeek...endOfWeek
    }

    var rangeOfSelection: ClosedRange<Date>? {
        guard let selection else { return nil }
        let startOfDay = selection.startOfDay
        let endOfDay = selection.endOfDay
        guard startOfDay < endOfDay else { return nil }
        return startOfDay...endOfDay
    }

    var averageForRange: Double {
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: visibleRange))
        guard let tasks else { return 0.0 }
        let sum = tasks.reduce(0.0, { $0 + ($1.completed ? 1.0 : 0.0) })
        let countOfDays = ceil(min(7, Date.now.timeIntervalSince(Date.now.startOfWeek) / (3600 * 24)))
        guard countOfDays > 0 else { return 0.0 }
        return sum / countOfDays
    }

    var countForRange: Int {
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: visibleRange))
        guard let tasks else { return 0 }
        return tasks.reduce(0, { $0 + ($1.completed ? 1 : 0) })
    }

    var tasksForSelection: [TaskNote]? {
        guard let selection = lastingSelection else { return nil }
        let startOfDay = selection.startOfDay
        let endOfDay = selection.endOfDay
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: startOfDay...endOfDay))
        guard let tasks else { return nil }
        return tasks.sorted { $0.completed && !$1.completed }
    }

    var countForSelection: Int {
        tasksForSelection?.reduce(0, { $0 + ($1.completed ? 1 : 0) }) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    chartTitle
                        .opacity(selection == nil ? 1.0 : 0.0)
                    selectedInfo
                        .opacity(selection == nil ? 0.0 : 1.0)
                }
                WeeklyCompletedTasks(selection: $selection,
                                     lastingSelection: $lastingSelection,
                                     scrollPosition: $scrollPosition,
                                     averageFocused: averageFocused)
                ChartToggle(isOn: $averageFocused, label: "Weekly Average", value: averageForRange, unit: "tasks", color: .barLongBreak)

                Divider()

                taskListForSelection
            }
            .padding()
            .fontDesign(.rounded)
            .listSectionSeparator(.hidden)
        }
        .navigationTitle("Completed Tasks")
        .onAppear {
            visibleDate = allTasks.first?.timestamp ?? Date.now
        }
    }

    @ViewBuilder var chartTitle: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(countForRange)")
                    .font(.title)
                Text("completed tasks this week")
                    .foregroundStyle(.secondary)
            }
            HStack {
                let start = visibleRange.lowerBound.formatted(.dateTime.month().day())
                let end = visibleRange.upperBound.formatted(.dateTime.month().day().year())
                Text("\(start) - \(end)")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder var selectedInfo: some View {
        if let selection {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(countForSelection)")
                        .font(.title)
                    Text("completed tasks")
                        .foregroundStyle(.secondary)
                }
                Text(selection.formatted(.dateTime.weekday().month().day().year()))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder var taskListForSelection: some View {
        if let tasks = tasksForSelection {
            Section {
                VStack(spacing: 10) {
                    ForEach(tasks) { taskItem in
                        LightweightTaskCell(taskItem: taskItem)
                        Divider()
                    }
                }
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Tasks (\(tasks.count))")
                    Spacer()
                    if let lastingSelection {
                        Text(lastingSelection.formatted(.dateTime.weekday().month().day().year()))
                    }
                }
                .font(.footnote)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
        } else {
            EmptyView()
        }
    }
}

@available(iOS 17, *)
#Preview {
    CompletedDetails()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
