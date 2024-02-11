//
//  PomodoroEstimationsDetails.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/9/24.
//

import SwiftUI
import Charts

@available(iOS 17, *)
struct WeeklyPomodoroEstimations: View {
    @Environment(\.managedObjectContext) var viewContext

    @Binding var selection: Date?
    @Binding var lastingSelection: Date?
    @Binding var scrollPosition: Date
    var showEstimates: Bool = true
    var showActuals: Bool = true

    @FetchRequest(fetchRequest: TasksData.pastTasksRequest(olderThan: Date.now))
    var allTasks: FetchedResults<TaskNote>

    let categoryOffset: Int = 1
    
    var taskAveragesByDay: [(key: Date, value: (estimation: Double, actual: Double))] {
        var tasksByDay: [Date: (estimation: Int, actual: Int, estimationCount: Int, actualCount: Int)] = [:]
        allTasks.forEach {
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
        let taskAverages = tasksByDay.mapValues {
            (
                estimation: Double($0.estimation) / Double($0.estimationCount),
                actual: Double($0.actual) / Double($0.actualCount)
            )
        }
        return taskAverages.sorted { $0.key < $1.key }
    }

    var body: some View {
        Chart {
            ForEach(taskAveragesByDay, id: \.key) { date, value in
                if value.estimation > 0 && value.actual > 0 && showEstimates && showActuals {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        yStart: .value("Estimation Comparison", value.estimation + Double(categoryOffset)),
                        yEnd: .value("Actual Comparison", value.actual + Double(categoryOffset)),
                        width: .fixed(14)
                    )
                    .foregroundStyle(disabledGradient(startPoint: .bottom, endPoint: .top))
                    .cornerRadius(8.0)
                    .opacity(0.7)
                    .offset(yStart: -4, yEnd: 4)
                    .zIndex(-1)
                }
                if value.estimation > 0 && showEstimates {
                    PointMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Estimation", value.estimation + Double(categoryOffset))
                    )
                    .foregroundStyle(Color.barRest)
                    .symbol(.circle)
                    .symbolSize(150)
                }
                if value.actual > 0 && showActuals {
                    PointMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Actual", value.actual + Double(categoryOffset))
                    )
                    .foregroundStyle(Color.end)
                    .symbol(.diamond)
                    .symbolSize(150)
                }
            }
            if let selection {
                RuleMark(
                    x: .value("Selected", selection, unit: .day)
                )
                .foregroundStyle(.tomato)
                .opacity(0.6)
                .zIndex(-1)
            }
            if let lastingSelection {
                RuleMark(
                    x: .value("Selected", lastingSelection, unit: .day)
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

        .chartYScale(domain: 0.0...8.0)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5, 6, 7]) { value in
                AxisTick()
                AxisGridLine()
                AxisValueLabel {
                    if let valueInt = value.as(Int.self) {
                        if valueInt == 1 {
                            Text("<1")
                        } else {
                            Text("\(valueInt - categoryOffset)")
                        }
                    }
                }
            }
        }
        .aspectRatio(1.3, contentMode: .fit)
        .chartXSelection(value: $selection)
        .onChange(of: selection) { selection in
            if let selection {
                lastingSelection = selection
            }
        }
        .transaction {
            $0.animation = nil
        }
    }
}

@available(iOS 17, *)
struct PomodoroEstimationsDetails: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @State var estimatesToggle: Bool = true
    @State var actualsToggle: Bool = true

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

    var tasksWithEstimatesForSelection: [TaskNote]? {
        guard let selection = lastingSelection else { return nil }
        let startOfDay = selection.startOfDay
        let endOfDay = selection.endOfDay
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: startOfDay...endOfDay))
        guard let tasks else { return nil }
        return tasks.filter { $0.pomosEstimate > 0 }
    }

    var diffOfPomosForVisibleRange: Double? {
        diffOfPomos(for: visibleRange)
    }

    var countsOfPomosForVisibleRange: (estimates: Int, actuals: Int, both: Int) {
        countsOfPomos(for: visibleRange)
    }
    
    var averagesForVisibleRange: (estimates: Double, actuals: Double) {
        averageOfPomos(for: visibleRange)
    }

    var diffOfPomosForSelection: Double? {
        guard let rangeOfSelection else { return nil }
        return diffOfPomos(for: rangeOfSelection)
    }

    var countsOfPomosForSelection: (estimates: Int, actuals: Int, both: Int) {
        guard let rangeOfSelection else { return (estimates: 0, actuals: 0, both: 0) }
        return countsOfPomos(for: rangeOfSelection)
    }

    var averagesForSelection: (estimates: Double, actuals: Double) {
        guard let rangeOfSelection else { return (estimates: 0.0, actuals: 0.0) }
        return averageOfPomos(for: rangeOfSelection)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ZStack(alignment: .bottomLeading) {
                    chartTitle
                        .opacity(selection == nil ? 1.0 : 0.0)
                    selectedInfo
                        .opacity(selection == nil ? 0.0 : 1.0)
                }
                legend
                    .padding(.vertical, -15)
                    .offset(y: 8)
                WeeklyPomodoroEstimations(selection: $selection,
                                          lastingSelection: $lastingSelection,
                                          scrollPosition: $scrollPosition,
                                          showEstimates: estimatesToggle,
                                          showActuals: actualsToggle)
                ChartToggle(isOn: $estimatesToggle, label: "Show Pomodoro Estimations", showData: false, color: .barRest)
                ChartToggle(isOn: $actualsToggle, label: "Show Actual Pomodoros", showData: false, color: .end)

                Divider()

                taskListForSelection
            }
            .padding()
            .fontDesign(.rounded)
            .listSectionSeparator(.hidden)
        }
        .navigationTitle("Pomodoro Estimations")
        .onAppear {
            visibleDate = allTasks.first?.timestamp ?? Date.now
        }
    }

    @ViewBuilder var chartTitle: some View {
        let averages = averagesForVisibleRange
        let counts = countsOfPomosForVisibleRange
        let hasEstimatesAndActuals = counts.estimates > 0 && counts.actuals > 0
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                differenceView(diff: hasEstimatesAndActuals ? averages.estimates - averages.actuals : nil,
                               count: counts.estimates)
                HStack {
                    let start = visibleRange.lowerBound.formatted(.dateTime.month().day())
                    let end = visibleRange.upperBound.formatted(.dateTime.month().day().year())
                    Text("\(start) - \(end)")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .leading) {
                averagesView(estimates: averages.estimates, actuals: averages.actuals)
            }
        }
    }

    @ViewBuilder var selectedInfo: some View {
        let averages = averagesForSelection
        let counts = countsOfPomosForSelection
        let hasEstimatesAndActuals = counts.estimates > 0 && counts.actuals > 0
        if let selection {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    differenceView(diff: hasEstimatesAndActuals ? averages.estimates - averages.actuals : nil,
                                   count: counts.estimates)
                    Text(selection.formatted(.dateTime.weekday().month().day().year()))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .leading) {
                    averagesView(estimates: averages.estimates, actuals: averages.actuals)
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder var legend: some View {
        let iconWidth = 12.0
        HStack {
            HStack {
                Circle()
                    .fill(.barRest)
                    .frame(width: iconWidth, height: iconWidth)
                Text("Estimate")
            }
            HStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.end)
                    .frame(width: iconWidth, height: iconWidth)
                    .rotationEffect(.degrees(45))
                Text("Actual")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder var taskListForSelection: some View {
        if let tasks = tasksWithEstimatesForSelection {
            Section {
                VStack(spacing: 10) {
                    ForEach(tasks) { taskItem in
                        LightweightTaskCell(taskItem: taskItem)
                        Divider()
                    }
                }
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Tasks with Estimations (\(tasks.count))")
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

    @ViewBuilder
    func differenceView(diff: Double?, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let diff {
                if diff < 0 {
                    Text(String(format: "Underestimating by %.1f", abs(diff)))
                        .font(.title3)
                    Text("Pomodoros")
                        .foregroundStyle(.secondary)
                } else if diff > 0 {
                    Text(String(format: "Overestimating by %.1f", abs(diff)))
                        .font(.title3)
                    Text("Pomodoros")
                        .foregroundStyle(.secondary)
                } else { // diff == 0
                    Text("No difference")
                        .font(.title3)
                    Text("from pomo estimations")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(" ")
                    .opacity(0.0)
                Text("\(count) estimations")
                    .font(.title3)
            }
        }
    }

    @ViewBuilder
    func averagesView(estimates: Double, actuals: Double) -> some View {
        VStack(alignment: .leading) {
            Text("Averages")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .offset(x: -5)
            Grid(alignment: .leading, verticalSpacing: -1) {
                GridRow {
                    Text(String(format: "%.1f", estimates))
                        .font(.body)
                        .monospacedDigit()
                        .foregroundStyle(.barRest)
                        .brightness(colorScheme == .dark ? 0.1 : 0.0)
                    Text("estimations")
                        .font(.footnote)
                }
                GridRow {
                    Text(String(format: "%.1f", actuals))
                        .font(.body)
                        .monospacedDigit()
                        .foregroundStyle(.end)
                        .brightness(colorScheme == .dark ? 0.1 : 0.0)
                    Text("actual pomos")
                        .font(.footnote)
                }
            }
        }
    }

    private func diffOfPomos(for range: ClosedRange<Date>) -> Double? {
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: range))
        guard let tasks else { return nil }
        var difference: Double?
        tasks.forEach {
            guard $0.pomosEstimate > 0 && $0.pomosActual > 0 && $0.completed else { return }
            if difference == nil {
                difference = 0.0
            }
            difference! += Double($0.pomosEstimate - $0.pomosActual)
        }
        return difference
    }

    private func averageOfPomos(for range: ClosedRange<Date>) -> (estimates: Double, actuals: Double) {
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: range))
        guard let tasks else { return (estimates: 0.0, actuals: 0.0) }
        var tasksByRange = (estimation: 0, actual: 0, estimationCount: 0, actualCount: 0)
        tasks.forEach {
            if $0.pomosEstimate > 0 {
                tasksByRange.estimation += Int($0.pomosEstimate)
                tasksByRange.estimationCount += 1
            }
            if $0.pomosActual > 0 && $0.completed {
                tasksByRange.actual += Int($0.pomosActual)
                tasksByRange.actualCount += 1
            }
        }
        let averageEstimation = tasksByRange.estimationCount == 0 ? 0.0 : Double(tasksByRange.estimation) / Double(tasksByRange.estimationCount)
        let averageActuals = tasksByRange.actualCount == 0 ? 0.0 : Double(tasksByRange.actual) / Double(tasksByRange.actualCount)
        return (estimates: averageEstimation, actuals: averageActuals)
    }

    private func countsOfPomos(for range: ClosedRange<Date>) -> (estimates: Int, actuals: Int, both: Int) {
        let tasks = try? viewContext.fetch(TasksData.rangeRequest(between: range))
        guard let tasks else { return (estimates: 0, actuals: 0, both: 0) }
        var counts = (estimates: 0, actuals: 0, both: 0)
        tasks.forEach {
            if $0.pomosEstimate > 0 {
                counts.estimates += 1
            }
            if $0.pomosActual > 0 && $0.completed {
                counts.actuals += 1
            }
            if $0.pomosEstimate > 0 && $0.pomosActual > 0 {
                counts.both += 1
            }
        }
        return counts
    }
}

@available(iOS 17, *)
#Preview {
    PomodoroEstimationsDetails()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
