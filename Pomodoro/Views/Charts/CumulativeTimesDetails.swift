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
    @Binding var selection: Date?
    @Binding var scrollPosition: Date
    var dataToggles: [PomoStatus: Bool]

    let widthRatio = 0.4

    @FetchRequest(fetchRequest: CumulativeTimeData.pastCumulativeTimeRequest)
    var cumulativeTimes: FetchedResults<CumulativeTime>

    var body: some View {
        Chart(cumulativeTimes) { item in
            if dataToggles[.work] ?? false {
                BarMark(
                    x: .value("Date", item.hourTimestamp ?? Date.now, unit: .hour),
                    y: .value("Work Time", item.work / 60),
                    width: .ratio(widthRatio)
                )
                .foregroundStyle(PomoStatus.work.gradient(startPoint: .bottom, endPoint: .top))
            }
            
            if dataToggles[.rest] ?? false {
                BarMark(
                    x: .value("Date", item.hourTimestamp ?? Date.now, unit: .hour),
                    y: .value("Rest Time", item.rest / 60),
                    width: .ratio(widthRatio)
                )
                .foregroundStyle(PomoStatus.rest.gradient(startPoint: .bottom, endPoint: .top))
            }
            
            if dataToggles[.longBreak] ?? false {
                BarMark(
                    x: .value("Date", item.hourTimestamp ?? Date.now, unit: .hour),
                    y: .value("Break Time", item.longBreak / 60),
                    width: .ratio(widthRatio)
                )
                .foregroundStyle(PomoStatus.longBreak.gradient(startPoint: .bottom, endPoint: .top))
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
        .chartYScale(domain: 0.0...60.0)
        .chartXAxis {
            AxisMarks(values: AxisMarkValues.stride(by: .hour, count: 6)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: Date.FormatStyle.dateTime.hour())
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .chartXSelection(value: $selection)
        .transaction {
            $0.animation = nil
        }
    }
}

@available(iOS 17, *)
struct WeeklyCumulativeChart: View {
    @Environment(\.managedObjectContext) var viewContext

    @Binding var selection: Date?
    @Binding var scrollPosition: Date
    var dataToggles: [PomoStatus: Bool]

    let widthRatio = 0.5

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

    var body: some View {
        Chart(cumulativeTimesByDay, id: \.key) { item in
            if dataToggles[.work] ?? false {
                BarMark(
                    x: .value("Date", item.key, unit: .day),
                    y: .value("Work Time", item.value[.work, default: 0] / 3600),
                    width: .ratio(widthRatio)
                )
                .foregroundStyle(PomoStatus.work.gradient(startPoint: .bottom, endPoint: .top))
            }

            if dataToggles[.rest] ?? false {
                BarMark(
                    x: .value("Date", item.key, unit: .day),
                    y: .value("Rest Time", item.value[.rest, default: 0] / 3600),
                    width: .ratio(widthRatio)
                )
                .foregroundStyle(PomoStatus.rest.gradient(startPoint: .bottom, endPoint: .top))
            }

            if dataToggles[.longBreak] ?? false {
                BarMark(
                    x: .value("Date", item.key, unit: .day),
                    y: .value("Break Time", item.value[.longBreak, default: 0] / 3600),
                    width: .ratio(widthRatio)
                )
                .foregroundStyle(PomoStatus.longBreak.gradient(startPoint: .bottom, endPoint: .top))
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
        .chartYScale(domain: 0.0...maxOfTimesByDay)
        .chartXAxis {
            AxisMarks(values: AxisMarkValues.stride(by: .day, count: 1)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: Date.FormatStyle.dateTime.weekday(.narrow), centered: true)
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .chartXSelection(value: $selection)
        .transaction {
            $0.animation = nil
        }
    }
}

@available(iOS 17, *)
struct CumulativeTimesDetails: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @State var chartScale: ChartScale = .week

    @State var averageFocused: Bool = false
    @State var toggles: [PomoStatus: Bool] = [.work: true, .rest: true, .longBreak: true]

    @State var selection: Date?
    @State var scrollPosition = Calendar.current.startOfDay(for: Date.now)
    @State var visibleDate = Date.now

    var totalsForRange: [PomoStatus: Double] {
        let times = try? viewContext.fetch(CumulativeTimeData.rangeRequest(between: visibleRange))
        guard let times else { return [.work: 0.0, .rest: 0.0, .longBreak: 0.0] }

        var totals: [PomoStatus: Double] = [.work: 0.0, .rest: 0.0, .longBreak: 0.0]
        times.forEach {
            totals[.work]? += $0.work
            totals[.rest]? += $0.rest
            totals[.longBreak]? += $0.longBreak
        }
        return totals.mapValues { $0 / 3600 }
    }

    var totalForRange: Double {
        totalsForRange.reduce(0.0, { $0 + $1.value })
    }

    var averageForRange: Double {
        // This should be average for the day, not average per hour
//        let times = try? viewContext.fetch(CumulativeTimeData.rangeRequest(between: visibleRange))
//        guard let times, times.count > 0 else { return 0.0 }
//        return totalForRange / Double(times.count)
        return -1.0
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
                                         dataToggles: toggles)
                case .week:
                    WeeklyCumulativeChart(selection: $selection,
                                          scrollPosition: $scrollPosition,
                                          dataToggles: toggles)
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
}
