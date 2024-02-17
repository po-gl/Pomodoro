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
    var showUncompleted: Bool

    let widthRatio = 0.3
    let radius = 10.0

    @FetchRequest(fetchRequest: TasksData.pastTasksRequest(olderThan: Date.now))
    var allTasks: FetchedResults<TaskNote>

    var tasksByDay: [(key: Date, value: (completed: Int, uncompleted: Int))] {
        var tasks: [Date: (completed: Int, uncompleted: Int)] = [:]
        allTasks.forEach {
            guard let timestamp = $0.timestamp else { return }
            let startOfDay = timestamp.startOfDay
            if $0.completed {
                tasks[startOfDay, default: (0, 0)].completed += 1
            } else {
                tasks[startOfDay, default: (0, 0)].uncompleted += 1
            }
        }
        return tasks.sorted { $0.key < $1.key }
    }

    var maxCompletedValue: Int {
        // Limit scope to past 30 days
        let maxCompleted = tasksByDay
            .suffix { -$0.key.timeIntervalSinceNow < 3600 * 24 * 30 }
            .max { $0.value.completed < $1.value.completed }?.value.completed ?? 0
        return max(maxCompleted, 3)
    }

    var maxUncompletedValue: Int {
        // Limit scope to past 30 days
        let maxUncompleted = tasksByDay
            .suffix { -$0.key.timeIntervalSinceNow < 3600 * 24 * 30 }
            .max { $0.value.uncompleted < $1.value.uncompleted }?.value.uncompleted ?? 0
        return max(maxUncompleted, 3)
    }

    var maxValue: Int {
        max(maxCompletedValue, maxUncompletedValue)
    }

    var averagesByWeek: [(key: Date, value: Double)] {
        let tasks = tasksByDay
        
        var totalsAndDayCounts: [Date: (total: Int, dayCounts: Int)] = [:]
        tasks.forEach {
            let startOfWeek = Calendar.current.startOfWeek(for: $0.key)

            totalsAndDayCounts[startOfWeek, default: (0, 0)].total += $0.value.completed
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
            ForEach(tasksByDay, id: \.key) { date, value in
                if showUncompleted {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Completed Tasks", value.completed),
                        width: .fixed(12)
                    )
                    .foregroundStyle(barStyle(isFocused: !averageFocused, isCompleted: true))
                    .position(by: .value("Completed", 0), axis: .horizontal, span: .ratio(0.5))
                    .cornerRadius(radius)
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Uncompleted Tasks", value.uncompleted),
                        width: .fixed(12)
                    )
                    .foregroundStyle(barStyle(isFocused: !averageFocused, isCompleted: false))
                    .position(by: .value("Uncompleted", 1), axis: .horizontal, span: .ratio(0.5))
                    .cornerRadius(radius)
                    .opacity(averageFocused ? 0.4 : 0.6)
                } else {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Completed Tasks", value.completed),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(barStyle(isFocused: !averageFocused, isCompleted: true))
                    .cornerRadius(radius)
                }
            }
            if averageFocused {
                ForEach(averagesByWeek, id: \.key) { average in
                    RuleMark(
                        xStart: .value("Start of Average", average.key),
                        xEnd: .value("End of Average", average.key.addingTimeInterval(3600 * 24 * 7)),
                        y: .value("Weekly Average", average.value)
                    )
                    .accessibilityIdentifier("averageMark\(average.key.formatted(.iso8601))")
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
            RuleMark(
                x: .value("Now", Date.now, unit: .hour)
            )
            .foregroundStyle(.blueberry)
            .lineStyle(StrokeStyle(dash: [3.0, 2.0]))
            .zIndex(-3)
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
            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                AxisTick()
                AxisGridLine()
                if let date = value.as(Date.self), date == Date.now.startOfDay {
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(.blueberry)
                } else {
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            // This top mark is only necessary while scrollPosition is not viable
            AxisMarks(position: .top, values: .stride(by: .day)) { value in
                if let date = value.as(Date.self), date == date.startOfWeek {
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .chartYScale(domain: 0...maxValue + 1)
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

    func barStyle(isFocused: Bool, isCompleted: Bool) -> LinearGradient {
        if isFocused {
            if isCompleted {
                return PomoStatus.end.gradient(startPoint: .top, endPoint: .bottom)
            } else {
                return LinearGradient(stops: [.init(color: .blueberry, location: 0.5),
                                              .init(color: Color(hex: 0xD3E7ED), location: 1.1)],
                                      startPoint: .top, endPoint: .bottom)
            }
        } else {
            return disabledGradient(startPoint: .top, endPoint: .bottom)
        }
    }
}

@available(iOS 17, *)
struct CompletedDetails: View {
    @Environment(\.managedObjectContext) var viewContext

    @State var averageFocused: Bool = false
    @State var showUncompleted: Bool = true

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
                                     averageFocused: averageFocused,
                                     showUncompleted: showUncompleted)
                ChartToggle(isOn: $averageFocused, label: "Weekly Average", value: averageForRange, unit: "tasks", color: .barLongBreak)
                ChartToggle(isOn: $showUncompleted, label: "Uncompleted Tasks", showData: false, color: .blueberry)
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
                    .accessibilityIdentifier("countValue")
                    .font(.title)
                Text("completed tasks this week")
                    .foregroundStyle(.secondary)
            }
            HStack {
                let start = visibleRange.lowerBound.formatted(.dateTime.month().day())
                let end = visibleRange.upperBound.formatted(.dateTime.month().day().year())
                Text("\(start) - \(end)")
                    .accessibilityIdentifier("visibleDate")
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
