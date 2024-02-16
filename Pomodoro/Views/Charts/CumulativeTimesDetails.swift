//
//  CumulativeTimesDetails.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/7/24.
//

import SwiftUI
import Charts

@available(iOS 17, *)
struct DailyCumulativeChart: View {
    @Environment(\.managedObjectContext) var viewContext

    @Binding var selection: Date?
    @Binding var scrollPosition: Date
    var dataToggles: [PomoStatus: Bool]

    var averageFocused: Bool

    let widthRatio = 0.4
    let radius = 5.0

    @FetchRequest(fetchRequest: CumulativeTimeData.pastCumulativeTimeRequest)
    var cumulativeTimes: FetchedResults<CumulativeTime>

    var lastTime: CumulativeTime? {
        let request = CumulativeTimeData.pastCumulativeTimeRequest
        request.fetchLimit = 1
        let lastTime = try? viewContext.fetch(request)
        return lastTime?.first
    }

    var averages: [(key: Date, value: Double)] {
        let times = try? viewContext.fetch(CumulativeTimeData.pastCumulativeTimeRequest)
        guard let times else { return [] }

        var totalsAndCounts: [Date: (Double, Int)] = [:]
        times.forEach {
            guard let hourTimestamp = $0.hourTimestamp else { return }
            let startOfDay = Calendar.current.startOfDay(for: hourTimestamp)

            var timeToAdd = 0.0
            if dataToggles[.work] ?? false {
                timeToAdd += $0.work
            }
            if dataToggles[.rest] ?? false {
                timeToAdd += $0.rest
            }
            if dataToggles[.longBreak] ?? false {
                timeToAdd += $0.longBreak
            }
            totalsAndCounts[startOfDay, default: (0.0, 0)].0 += timeToAdd
            totalsAndCounts[startOfDay, default: (0.0, 0)].1 += 1
        }
        let averages = totalsAndCounts.mapValues { $0 / Double($1) }
        return averages.sorted { $0.key < $1.key }
    }

    var body: some View {
        Chart {
            ForEach(cumulativeTimes) { item in
                if dataToggles[.work] ?? false {
                    BarMark(
                        x: .value("Date", item.hourTimestamp ?? Date.now, unit: .hour),
                        y: .value("Work Time", item.work / 60),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(barStyle(for: .work, isFocused: !averageFocused))
                    .cornerRadius(radius)
                }
                
                if dataToggles[.rest] ?? false {
                    BarMark(
                        x: .value("Date", item.hourTimestamp ?? Date.now, unit: .hour),
                        y: .value("Rest Time", item.rest / 60),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(barStyle(for: .rest, isFocused: !averageFocused))
                    .cornerRadius(radius)
                }
                
                if dataToggles[.longBreak] ?? false {
                    BarMark(
                        x: .value("Date", item.hourTimestamp ?? Date.now, unit: .hour),
                        y: .value("Break Time", item.longBreak / 60),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(barStyle(for: .longBreak, isFocused: !averageFocused))
                    .cornerRadius(radius)
                }
            }
            if averageFocused {
                ForEach(averages, id: \.key) { average in
                    RuleMark(
                        xStart: .value("Start of Average", average.key),
                        xEnd: .value("End of Average", average.key.addingTimeInterval(3600 * 24)),
                        y: .value("Daily Average", average.value / 60)
                    )
                    .accessibilityIdentifier("averageMark\(average.key.formatted(.iso8601))")
                    .foregroundStyle(.end)
                    .annotation(
                        position: .top,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) { context in
                        let width = context.targetSize.width
                        Text(String(format: "%.1f min", average.value / 60))
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 2)
                            .foregroundStyle(.black)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.end))
                            .padding(.leading, 3)
                            .frame(minWidth: width > 0 ? width : 0, alignment: .leading)
                    }
                }
            }
            if let selection {
                RuleMark(
                    x: .value("Selected", selection, unit: .hour)
                )
                .foregroundStyle(.tomato)
                .opacity(0.6)
                .zIndex(-1)
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartScrollTargetBehavior(
            .valueAligned(
                matching: DateComponents(minute: 0),
                majorAlignment: .matching(DateComponents(hour: 0))
            )
        )
        // Scrolling with a binding causes an unacceptable amount of lag
        // this is likely a bug with Charts that occurs with all but the lightest Sequences as data
//        .chartScrollPosition(x: $scrollPosition)
        .chartScrollPosition(initialX: Date.now.startOfDay)

        .chartXScale(domain: (cumulativeTimes.last?.hourTimestamp ?? Date.now.startOfDay)...(lastTime?.hourTimestamp?.endOfDay ?? Date.now.endOfDay))
        .chartXVisibleDomain(length: 3600 * 24 + 1)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
            // This top mark is only necessary while scrollPosition is not viable
            AxisMarks(position: .top, values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }

        .chartYScale(domain: 0.0...65.0)
        .chartYAxis {
            AxisMarks(values: [0, 15, 30, 45, 60]) { value in
                let valueInt = value.as(Int.self) ?? 0
                if valueInt == 15 || valueInt == 45 {
                    AxisGridLine(stroke: StrokeStyle(dash: [2.0, 2.0]))
                } else {
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel(collisionResolution: .greedy(priority: 0.0)) {
                        Text("\(valueInt) min")
                    }
                }
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .chartXSelection(value: $selection)
        .transaction {
            $0.animation = nil
        }
    }

    func barStyle(for status: PomoStatus, isFocused: Bool) -> LinearGradient {
        if isFocused {
            status.gradient(startPoint: .bottom, endPoint: .top)
        } else {
            disabledGradient(startPoint: .bottom, endPoint: .top)
        }
    }
}

@available(iOS 17, *)
struct WeeklyCumulativeChart: View {
    @Environment(\.managedObjectContext) var viewContext

    @Binding var selection: Date?
    @Binding var scrollPosition: Date
    var dataToggles: [PomoStatus: Bool]

    var averageFocused: Bool

    let widthRatio = 0.5
    let radius = 4.0

    @FetchRequest(fetchRequest: CumulativeTimeData.pastCumulativeTimeRequest)
    var cumulativeTimes: FetchedResults<CumulativeTime>

    var lastTime: CumulativeTime? {
        let request = CumulativeTimeData.pastCumulativeTimeRequest
        request.fetchLimit = 1
        let lastTime = try? viewContext.fetch(request)
        return lastTime?.first
    }

    var cumulativeTimesByDay: [(key: Date, value: [PomoStatus: Double])] {
        let times = try? viewContext.fetch(CumulativeTimeData.pastCumulativeTimeRequest)
        guard let times else { return [] }

        var timesByDay: [Date: [PomoStatus: Double]] = [:]
        times.forEach {
            guard let hourTimestamp = $0.hourTimestamp else { return }
            let startOfDay = Calendar.current.startOfDay(for: hourTimestamp)
            
            timesByDay[startOfDay, default: [:]][.work, default: 0] += $0.work
            timesByDay[startOfDay, default: [:]][.rest, default: 0] += $0.rest
            timesByDay[startOfDay, default: [:]][.longBreak, default: 0] += $0.longBreak
        }
        return timesByDay.sorted { $0.key < $1.key }
    }

    var maxOfTimesByDay: Double {
        let times = cumulativeTimesByDay
        let maxTime = times.max { $0.value.reduce(0.0, { $0 + $1.value }) < $1.value.reduce(0.0, { $0 + $1.value })}
        if let maxTime {
            return maxTime.value.reduce(0.0, { $0 + $1.value }) / 3600
        } else {
            return 5.0
        }
    }

    var averages: [(key: Date, value: Double)] {
        let times = cumulativeTimesByDay

        var totalsAndCounts: [Date: (Double, Int)] = [:]
        times.forEach {
            let startOfWeek = Calendar.current.startOfWeek(for: $0.key)

            var timeToAdd = 0.0
            if dataToggles[.work] ?? false {
                timeToAdd += $0.value[.work, default: 0]
            }
            if dataToggles[.rest] ?? false {
                timeToAdd += $0.value[.rest, default: 0]
            }
            if dataToggles[.longBreak] ?? false {
                timeToAdd += $0.value[.longBreak, default: 0]
            }
            totalsAndCounts[startOfWeek, default: (0.0, 0)].0 += timeToAdd
            totalsAndCounts[startOfWeek, default: (0.0, 0)].1 += 1
        }
        let averages = totalsAndCounts.mapValues { $0 / Double($1) }
        return averages.sorted { $0.key < $1.key }
    }

    var body: some View {
        Chart {
            ForEach(cumulativeTimesByDay, id: \.key) { item in
                if dataToggles[.work] ?? false {
                    BarMark(
                        x: .value("Date", item.key, unit: .day),
                        y: .value("Work Time", item.value[.work, default: 0] / 3600),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(barStyle(for: .work, isFocused: !averageFocused))
                    .cornerRadius(radius)
                }
                
                if dataToggles[.rest] ?? false {
                    BarMark(
                        x: .value("Date", item.key, unit: .day),
                        y: .value("Rest Time", item.value[.rest, default: 0] / 3600),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(barStyle(for: .rest, isFocused: !averageFocused))
                    .cornerRadius(radius)
                }
                
                if dataToggles[.longBreak] ?? false {
                    BarMark(
                        x: .value("Date", item.key, unit: .day),
                        y: .value("Break Time", item.value[.longBreak, default: 0] / 3600),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(barStyle(for: .longBreak, isFocused: !averageFocused))
                    .cornerRadius(radius)
                }
            }
            if averageFocused {
                ForEach(averages, id: \.key) { average in
                    RuleMark(
                        xStart: .value("Start of Average", average.key),
                        xEnd: .value("End of Average", average.key.addingTimeInterval(3600 * 24 * 7)),
                        y: .value("Weekly Average", average.value / 3600)
                    )
                    .foregroundStyle(.end)
                    .annotation(
                        position: .top,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) { context in
                        let width = context.targetSize.width
                        Text(String(format: "%.1f hrs", average.value / 3600))
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 2)
                            .foregroundStyle(.black)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.end))
                            .padding(.leading, 3)
                            .frame(minWidth: width > 0 ? width : 0, alignment: .leading)
                    }
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

        .chartXScale(domain: (cumulativeTimes.last?.hourTimestamp?.startOfWeek ?? Date.now.startOfWeek)...(lastTime?.hourTimestamp?.endOfWeek ?? Date.now.endOfWeek))
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

        .chartYScale(domain: 0.0...maxOfTimesByDay + 1.0)
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(collisionResolution: .greedy(priority: 0.0)) {
                    Text("\(value.as(Int.self) ?? 0) hrs")
                }
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .chartXSelection(value: $selection)
        .transaction {
            $0.animation = nil
        }
    }

    func barStyle(for status: PomoStatus, isFocused: Bool) -> LinearGradient {
        if isFocused {
            status.gradient(startPoint: .bottom, endPoint: .top)
        } else {
            disabledGradient(startPoint: .bottom, endPoint: .top)
        }
    }
}

@available(iOS 17, *)
struct CumulativeTimesDetails: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @State var chartScale: ChartScale = .day

    @State var averageFocused: Bool = false
    @State var toggles: [PomoStatus: Bool] = [.work: true, .rest: true, .longBreak: true]

    @State var selection: Date?
    @State var scrollPosition = Calendar.current.startOfDay(for: Date.now)
    @State var visibleDate = Date.now

    @State var showData = false

    var lastTime: CumulativeTime? {
        let request = CumulativeTimeData.pastCumulativeTimeRequest
        request.fetchLimit = 1
        let lastTime = try? viewContext.fetch(request)
        return lastTime?.first
    }

    var totalsForRange: [PomoStatus: Double] {
        let times = try? viewContext.fetch(CumulativeTimeData.rangeRequest(between: visibleRange))
        guard let times else { return [:] }

        var totals: [PomoStatus: Double] = [:]
        times.forEach {
            totals[.work, default: 0] += $0.work
            totals[.rest, default: 0] += $0.rest
            totals[.longBreak, default: 0] += $0.longBreak
        }
        return totals.mapValues { $0 / 3600 }
    }

    var totalForRange: Double {
        totalsForRange.reduce(0.0, { $0 + $1.value })
    }

    var averageForRange: Double {
        let times = try? viewContext.fetch(CumulativeTimeData.rangeRequest(between: visibleRange))
        guard let times, times.count > 0 else { return 0.0 }
        var uniqueDates: Set<Date> = Set()
        times.forEach {
            guard let hourTimestamp = $0.hourTimestamp else { return }
            let startOfUnit = startOfUnit(for: hourTimestamp)
            uniqueDates.insert(startOfUnit)
        }
        return totalForRange / Double(uniqueDates.count)
    }

    var totalsForSelection: [PomoStatus: Double] {
        guard let selection else { return [:] }
        let times = try? viewContext.fetch(CumulativeTimeData.rangeRequest(between: getRangeForScale(selection)))
        guard let times, times.count > 0 else { return [:] }

        var totals: [PomoStatus: Double] = [:]
        times.forEach {
            totals[.work, default: 0] += $0.work
            totals[.rest, default: 0] += $0.rest
            totals[.longBreak, default: 0] += $0.longBreak
        }
        return totals.mapValues { $0 }
    }

    var totalForSelection: Double {
        totalsForSelection.reduce(0.0, { $0 + $1.value })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Chart Scale", selection: $chartScale) {
                    Text("Daily").tag(ChartScale.day)
                    Text("Weekly").tag(ChartScale.week)
                }
                .accessibilityIdentifier("chartScalePicker")
                .pickerStyle(.segmented)
                ZStack(alignment: .bottomLeading) {
                    chartTitle
                        .opacity(selection == nil ? 1.0 : 0.0)
                    selectedInfo
                        .opacity(selection == nil ? 0.0 : 1.0)
                }
                switch chartScale {
                case .day:
                    DailyCumulativeChart(selection: $selection,
                                         scrollPosition: $scrollPosition,
                                         dataToggles: toggles,
                                         averageFocused: averageFocused)
                    ChartToggle(isOn: $averageFocused, label: "Daily Average", value: averageForRange, unit: "hours", color: .end)
                case .week:
                    WeeklyCumulativeChart(selection: $selection,
                                          scrollPosition: $scrollPosition,
                                          dataToggles: toggles,
                                          averageFocused: averageFocused)
                    ChartToggle(isOn: $averageFocused, label: "Weekly Average", value: averageForRange, unit: "hours", color: .end)
                default:
                    EmptyView()
                }
                Divider()
                chartToggles
                Divider()
                allDataButton
                    .navigationDestination(isPresented: $showData) {
                        CumulativeTimesDataList()
                    }
            }
            .padding()
            .fontDesign(.rounded)
            .listRowSeparator(.hidden)
            .onChangeWithThrottle(of: scrollPosition, for: 0.6) { date in
                visibleDate = date
            }
            .onAppear {
                visibleDate = lastTime?.hourTimestamp ?? Date.now
            }
        }
        .listStyle(.plain)
        .navigationTitle("Cumulative Times")
    }

    @ViewBuilder var chartTitle: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", totalForRange))
                    .accessibilityIdentifier("totalHourValue")
                    .font(.title)
                Text("total hours")
                    .foregroundStyle(.secondary)
            }
            switch chartScale {
            case .day:
                Text(visibleDate.formatted(.dateTime.weekday().month().day().year()))
                    .accessibilityIdentifier("visibleDate")
                    .foregroundStyle(.secondary)
            case .week:
                HStack {
                    let start = visibleRange.lowerBound.formatted(.dateTime.month().day())
                    let end = visibleRange.upperBound.formatted(.dateTime.month().day().year())
                    Text("\(start) - \(end)")
                        .accessibilityIdentifier("visibleDate")
                        .foregroundStyle(.secondary)
                }
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder var selectedInfo: some View {
        let total = totalForSelection
        if let selection {
            HStack {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(total.minOrHr(includeUnit: false))
                            .font(.title)
                        Text("total \(total < 3600 ? "minutes" : "hours")")
                            .fixedSize()
                            .foregroundStyle(.secondary)
                    }
                    switch chartScale {
                    case .day:
                        Text(selection.formatted(.dateTime.hour().weekday().month().day().year()))
                            .foregroundStyle(.secondary)
                    case .week:
                        Text(selection.formatted(.dateTime.weekday().month().day().year()))
                            .foregroundStyle(.secondary)
                    default:
                        EmptyView()
                    }
                }
                .fixedSize()
                .frame(width: 210, alignment: .leading)
                Spacer()
                Grid(alignment: .leading, verticalSpacing: -1) {
                    GridRow {
                        selectionInfoRow(for: .work)
                    }
                    GridRow {
                        selectionInfoRow(for: .rest)
                    }
                    GridRow {
                        selectionInfoRow(for: .longBreak)
                    }
                }
                .fixedSize()
                .frame(width: 100, alignment: .leading)
                Spacer()
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func selectionInfoRow(for status: PomoStatus) -> some View {
        Text(status == .longBreak ? "Break" : status.rawValue)
            .font(.footnote)
        Text(totalsForSelection[status, default: 0].minOrHr())
            .font(.callout)
            .monospacedDigit()
            .fontWeight(.medium)
            .foregroundStyle(status.color)
            .brightness(colorScheme == .dark ? 0.1 : 0.0)
    }

    @ViewBuilder var chartToggles: some View {
        VStack(spacing: 15) {
            ForEach([PomoStatus.work, PomoStatus.rest, PomoStatus.longBreak], id: \.self) { status in
                let isOn = Binding(get: { toggles[status] ?? false }, set: { toggles[status] = $0 })
                ChartToggle(isOn: isOn,
                            label: status.rawValue,
                            value: totalsForRange[status] ?? 0.0,
                            unit: "hours",
                            color: status.color)
            }
        }
    }

    @ViewBuilder var allDataButton: some View {
        Button(action: {
            showData = true
        }) {
            Text("All Data")
                .foregroundStyle(.tomato)
        }
        .accessibilityIdentifier("allDataButton")
        .tint(.tomato)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var visibleRange: ClosedRange<Date> {
        switch chartScale {
        case .week:
            let startOfWeek = Calendar.current.startOfWeek(for: visibleDate)
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)! - 1.0
            return startOfWeek...endOfWeek
        default:
            let startOfDay = Calendar.current.startOfDay(for: visibleDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)! - 1.0
            return startOfDay...endOfDay
        }
    }

    func getRangeForScale(_ date: Date) -> ClosedRange<Date> {
        switch chartScale {
        case .week:
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)! - 1.0
            return startOfDay...endOfDay
        default:
            let startOfHour = Calendar.current.startOfHour(for: date)
            let endOfHour = Calendar.current.date(byAdding: .hour, value: 1, to: startOfHour)! - 1.0
            return startOfHour...endOfHour
        }
    }

    func startOfUnit(for date: Date) -> Date {
        switch chartScale {
        case .week:
            return Calendar.current.startOfDay(for: date)
        default:
            return Calendar.current.startOfHour(for: date)
        }
    }
}

@available(iOS 17, *)
#Preview {
    NavigationStack {
        CumulativeTimesDetails()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
