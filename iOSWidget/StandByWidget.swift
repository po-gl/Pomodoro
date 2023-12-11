//
//  StandByWidget.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/10/23.
//

import SwiftUI
import WidgetKit

struct StandByWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidgetTimelineProvider(withProgress: true)) { entry in
            iOSWidgetView(entry: entry)
                .unredacted()
        }
        .configurationDisplayName("Pomodoro")
        .description("Track your pomodoro timer.")
    }
}

struct StandByWidgetEntryView: View {
    var entry: WidgetTimelineProvider.Entry

    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.status.rawValue)")
                    .font(.title2).fontWeight(.light).fontDesign(.monospaced)
                    .foregroundColor(entry.status.color)
                HStack(spacing: 8) {
                    Text(timerInterval: entry.timerInterval, pauseTime: entry.isPaused ? entry.timerInterval.lowerBound : nil)
                        .foregroundColor(.white)
                        .font(.title).fontWeight(.regular)
                        .monospacedDigit()
                    Text(entry.status.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
            }
            .containerBackground(.black, for: .widget)
        } else {
            ZStack {
                Rectangle().foregroundColor(.black)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(entry.status.rawValue)")
                        .font(.title2).fontWeight(.light).fontDesign(.monospaced)
                        .foregroundColor(entry.status.color)
                    HStack(spacing: 8) {
                        Text(timerInterval: entry.timerInterval, pauseTime: entry.isPaused ? entry.timerInterval.lowerBound : nil)
                            .foregroundColor(.white)
                            .font(.title).fontWeight(.regular)
                            .monospacedDigit()
                        Text(entry.status.icon)
                            .font(.system(size: 20))
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

struct StandByWidget_Previews: PreviewProvider {
    static var pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { _ in return })

    static var previews: some View {
        let timerInterval = Date.now...Date.now.addingTimeInterval(60)
        let entry = PomoTimelineEntry(date: Date.now,
                                      status: .rest,
                                      task: nil,
                                      timerInterval: timerInterval,
                                      isPaused: false,
                                      currentSegment: 3,
                                      segmentCount: 6,
                                      configuration: ConfigurationIntent())
        StandByWidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
