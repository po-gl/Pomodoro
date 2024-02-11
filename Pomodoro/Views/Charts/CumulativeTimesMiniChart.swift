//
//  CumulativeTimesMiniChart.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/9/24.
//

import SwiftUI
import Charts

@available(iOS 17, *)
struct CumulativeTimesMiniChart: View {
    @Environment(\.managedObjectContext) var viewContext

    let widthRatio = 0.55
    let radius = 5.0
    
    @FetchRequest(fetchRequest: CumulativeTimeData.latestTimeRequest)
    var latestTimeResults: FetchedResults<CumulativeTime>

    var lastTime: CumulativeTime? {
        return latestTimeResults.first
    }

    var lastDayTimes: [(key: Date, value: [PomoStatus: Double])] {
        guard let lastTime, let timeStamp = lastTime.hourTimestamp else { return [] }
        let times = try? viewContext.fetch(CumulativeTimeData.rangeRequest(between: timeStamp.startOfDay...timeStamp.endOfDay))
        var allTimes = [Date: [PomoStatus: Double]]()
        times?.forEach {
            guard let hourTimestamp = $0.hourTimestamp else { return }
            allTimes[hourTimestamp, default: [:]][.work, default: 0] = $0.work
            allTimes[hourTimestamp, default: [:]][.rest, default: 0] = $0.rest
            allTimes[hourTimestamp, default: [:]][.longBreak, default: 0] = $0.longBreak
        }
        for hour in stride(from: timeStamp.startOfDay, to: timeStamp.endOfDay, by: 3600) {
            if !allTimes.contains(where: { $0.key == hour }) {
                allTimes[hour, default: [:]] = [.work: 0, .rest: 0, .longBreak: 0]
            }
        }
        return allTimes.sorted { $0.key < $1.key }
    }

    var body: some View {
        Chart {
            ForEach(lastDayTimes, id: \.key) { date, values in
                
                if values.reduce(0.0, { $0 + $1.value }) < 0.01 {
                    // Placeholder BarMark
                    BarMark(
                        x: .value("Date", date, unit: .hour),
                        y: .value("", 4)
                    )
                    .foregroundStyle(disabledGradient(startPoint: .bottom, endPoint: .top))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(0.5)
                } else {
                    BarMark(
                        x: .value("Date", date, unit: .hour),
                        y: .value("Work Time", values[.work, default: 0] / 60),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(PomoStatus.work.gradient(startPoint: .bottom, endPoint: .top))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .zIndex(3)
                    
                    BarMark(
                        x: .value("Date", date, unit: .hour),
                        y: .value("Rest Time", values[.rest, default: 0] / 60),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(PomoStatus.rest.gradient(startPoint: .bottom, endPoint: .top))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .zIndex(2)
                    
                    BarMark(
                        x: .value("Date", date, unit: .hour),
                        y: .value("Break Time", values[.longBreak, default: 0] / 60),
                        width: .ratio(widthRatio)
                    )
                    .foregroundStyle(PomoStatus.longBreak.gradient(startPoint: .bottom, endPoint: .top))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .zIndex(1)
                }
            }
        }
        .chartXScale(domain: (lastTime?.hourTimestamp?.startOfDay ?? Date.now.startOfDay)...(lastTime?.hourTimestamp?.endOfDay ?? Date.now.endOfDay))
        .chartXVisibleDomain(length: 3600 * 24 + 1)
        .chartXAxis { }
        .chartYScale(domain: 0.0...60.0)
        .chartYAxis {
            AxisMarks(values: [0, 15, 30]) { value in
                let valueInt = value.as(Int.self) ?? 0
                if valueInt == 15 {
                    AxisGridLine(stroke: StrokeStyle(dash: [2.0, 2.0]))
                        .foregroundStyle(.grayedOut)
                } else {
                    AxisGridLine()
                        .foregroundStyle(.grayedOut)
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    CumulativeTimesMiniChart()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 200, height: 100)
}
