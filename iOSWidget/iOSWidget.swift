//
//  iOSWidget.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

import WidgetKit
import SwiftUI

struct iOSWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: true)) { entry in
            iOSWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro")
        .description("Track your pomodoro timer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct iOSWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        if #available(iOSApplicationExtension 17, *) {
            content
                .containerBackground(for: .widget) {
                    Color.black
                    LinearGradient(colors: [entry.status.color, .clear], startPoint: .top, endPoint: .bottom)
                        .opacity(entry.isPaused ? 0.13 : 0.2)
                        .animation(.default, value: entry.isPaused)
                }
        } else {
            ZStack {
                Rectangle().fill(.black)
                LinearGradient(colors: [entry.status.color, .clear], startPoint: .top, endPoint: .bottom)
                    .opacity(entry.isPaused ? 0.13 : 0.2)
                    .animation(.default, value: entry.isPaused)
                content
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder var content: some View {
        if widgetFamily == .systemSmall {
            smallLayout
        } else {
            mediumLayout
        }
    }

    @ViewBuilder var mediumLayout: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                VStack(alignment:. leading, spacing: 5) {
                    statusView
                    timerEndView
                        .offset(x: 4)
                }
                Spacer()
                timerView
                    .offset(y: -5)
            }
            Spacer()
            WidgetProgressBar(timerInterval: entry.timerInterval,
                              currentSegment: entry.currentSegment,
                              segmentCount: entry.segmentCount,
                              pausedAt: entry.isPaused ? entry.timerInterval.lowerBound : nil)
            .frame(height: 5)
        }
    }

    @ViewBuilder var smallLayout: some View {
        VStack(alignment: .trailing, spacing: 0) {
            timerView
                .offset(y: -5)
            Spacer()
            HStack(spacing: 0) {
                VStack(alignment:. leading, spacing: 5) {
                    statusView
                    timerEndView
                        .offset(x: 4)
                }
                Spacer()
            }
            Spacer()
            WidgetProgressBar(timerInterval: entry.timerInterval,
                              currentSegment: entry.currentSegment,
                              segmentCount: entry.segmentCount,
                              pausedAt: entry.isPaused ? entry.timerInterval.lowerBound : nil)
            .frame(height: 5)
        }
    }

    @ViewBuilder var timerView: some View {
        let startDate = entry.timerInterval.lowerBound
        let endDate = entry.timerInterval.upperBound
        if entry.isPaused {
            Text(endDate.timeIntervalSince(startDate).compactTimerFormatted())
                .font(.system(size: 42, weight: .light))
                .monospacedDigit()
                .frame(width: 115, alignment: .trailing)
                .foregroundStyle(.white)
        } else {
            Text(timerInterval: entry.timerInterval, countsDown: true)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 42, weight: .light))
                .monospacedDigit()
                .frame(width: 115)
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
        }
    }

    @ViewBuilder var statusView: some View {
        let task = entry.task ?? ""
        Text(task != "" ? task : entry.status.rawValue)
            .font(.system(.headline, design: .rounded, weight: .medium))
            .lineLimit(widgetFamily == .systemSmall ? 1 : 3)
            .foregroundStyle(.black)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(entry.status.color)
                    .brightness(0.2)
                    .shadow(radius: 2, x: 2, y: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .offset(x: 3, y: 3)
                            .foregroundStyle(entry.status.color)
                            .brightness(0.0)
                    )
            )
    }

    @ViewBuilder var timerEndView: some View {
        let endTime = entry.isPaused ? "--:--" : timeFormatter.string(from: entry.timerInterval.lowerBound)
        Text("until \(endTime)")
            .font(.system(.subheadline, design: .rounded, weight: .regular))
            .monospacedDigit()
            .opacity(0.6)
            .foregroundStyle(.white)
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()

struct iOSWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })

    static var previews: some View {
        let timerInterval = Date.now...Date.now.addingTimeInterval(60)
        let entry = PomoTimelineEntry(date: Date.now,
                                      status: .work,
                                      task: nil,
                                      timerInterval: timerInterval,
                                      isPaused: false,
                                      currentSegment: 5,
                                      segmentCount: 6,
                                      configuration: ConfigurationIntent())
        Group {
            iOSWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            iOSWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            iOSWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
