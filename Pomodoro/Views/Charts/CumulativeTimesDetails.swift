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
                    .foregroundStyle(.end)
                }
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

        .chartXScale(domain: (cumulativeTimes.last?.hourTimestamp ?? Date.now.startOfDay)...Date.now.endOfDay)
        .chartXVisibleDomain(length: 3600 * 24 + 1)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }

        .chartYScale(domain: 0.0...60.0)
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
            if averageFocused {
                if let average = averages.first(where: { $0.key == scrollPosition.startOfDay }) {
                    AxisMarks(values: [average.value / 60]) { value in
                        AxisValueLabel(collisionResolution: .greedy(priority: 1.0)) {
                            Text(String(format: "%.1f min", value.as(Double.self) ?? 0))
                                .foregroundStyle(.end)
                        }
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
    let radius = 6.0

    @FetchRequest(fetchRequest: CumulativeTimeData.pastCumulativeTimeRequest)
    var cumulativeTimes: FetchedResults<CumulativeTime>

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
                }
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

        .chartXScale(domain: (cumulativeTimes.last?.hourTimestamp ?? Date.now.startOfWeek)...Date.now.endOfWeek)
        .chartXVisibleDomain(length: 3600 * 24 * 7 + 1)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
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
            if averageFocused {
                if let average = averages.first(where: { $0.key == scrollPosition.startOfWeek }) {
                    AxisMarks(values: [average.value / 3600]) { value in
                        AxisValueLabel(collisionResolution: .greedy(priority: 1.0)) {
                            Text(String(format: "%.1f hrs", value.as(Double.self) ?? 0))
                                .foregroundStyle(.end)
                        }
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
struct CumulativeTimesDetails: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @State var chartScale: ChartScale = .day

    @State var averageFocused: Bool = false
    @State var toggles: [PomoStatus: Bool] = [.work: true, .rest: true, .longBreak: true]

    @State var selection: Date?
    @State var scrollPosition = Calendar.current.startOfDay(for: Date.now)
    @State var visibleDate = Date.now

    var totalsForRange: [PomoStatus: Double] {
        let times = try? viewContext.fetch(CumulativeTimeData.rangeRequest(between: visibleRange))
        guard let times else { return [.work: 0.0, .rest: 0.0, .longBreak: 0.0] }

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

    var body: some View {
        List {
            VStack(spacing: 20) {
                Picker("Chart Scale", selection: $chartScale) {
                    Text("Daily").tag(ChartScale.day)
                    Text("Weekly").tag(ChartScale.week)
                }
                .pickerStyle(.segmented)
                chartTitle
                switch chartScale {
                case .day:
                    DailyCumulativeChart(selection: $selection,
                                         scrollPosition: $scrollPosition,
                                         dataToggles: toggles,
                                         averageFocused: averageFocused)
                case .week:
                    WeeklyCumulativeChart(selection: $selection,
                                          scrollPosition: $scrollPosition,
                                          dataToggles: toggles,
                                          averageFocused: averageFocused)
                default:
                    EmptyView()
                }

                ChartToggle(isOn: $averageFocused, label: "Daily Average", value: averageForRange, unit: "hours", color: .end)
                Divider()
                chartToggles
            }
            .listRowSeparator(.hidden)
            .onChangeWithThrottle(of: scrollPosition, for: 0.6) { date in
                visibleDate = date
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder var chartTitle: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.1f", totalForRange))
                        .font(.title)
                    Text("total hours")
                        .foregroundStyle(.secondary)
                }
                switch chartScale {
                case .day:
                    Text("\(visibleDate.formatted(.dateTime.weekday().month().day().year()))")
                        .foregroundStyle(.secondary)
                case .week:
                    HStack {
                        let start = visibleRange.lowerBound.formatted(.dateTime.month().day())
                        let end = visibleRange.upperBound.formatted(.dateTime.month().day().year())
                        Text("\(start) - \(end)")
                            .foregroundStyle(.secondary)
                    }
                default:
                    EmptyView()
                }
            }
            Spacer()
        }
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

    func startOfUnit(for date: Date) -> Date {
        switch chartScale {
        case .week:
            return Calendar.current.startOfDay(for: date)
        default:
            return Calendar.current.startOfHour(for: date)
        }
    }
}
