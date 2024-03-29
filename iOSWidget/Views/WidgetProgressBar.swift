//
//  WidgetProgressBar.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/7/23.
//

import SwiftUI

/// This view relies on a work-rest...work-rest-longbreak sequence
/// and will need to change (along with live activity state) to allow flexible sequences
struct WidgetProgressBar: View {
    let timerInterval: ClosedRange<Date>

    let currentSegment: Int
    let segmentCount: Int

    let pausedAt: Date?

    let workDuration: TimeInterval
    let restDuration: TimeInterval
    let breakDuration: TimeInterval

    let spacing: CGFloat = 2.0

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                let progressAtPause = pausedAt?.progressBetween(timerInterval.lowerBound, timerInterval.upperBound)
                ForEach(0..<segmentCount-1, id: \.self) { i in // -1 to take off ".end" segment
                    let status = getStatus(for: i)
                    let percent = getPercent(for: status)

                    // If paused at start
                    if let progressAtPause, progressAtPause < 0.00001 && currentSegment == 0 {
                        ProgressView(value: 1.0)
                            .progressViewStyle(ProgressBarStyle(color: status.color, withOverlay: true))
                            .frame(width: geometry.frame(in: .local).size.width * percent - spacing)

                    // In-progress segment
                    } else if i == currentSegment {
                        if let progressAtPause {
                            ProgressView(value: progressAtPause)
                                .progressViewStyle(ProgressBarStyle(color: status.color))
                                .frame(width: geometry.frame(in: .local).size.width * percent - spacing)
                        } else {
                            ProgressView(timerInterval: timerInterval, countsDown: false)
                                .progressViewStyle(ProgressBarStyle(color: status.color))
                                .frame(width: geometry.frame(in: .local).size.width * percent - spacing)
                        }

                    // Either a past or future segment
                    } else if i < currentSegment {
                        ProgressView(value: 1.0)
                            .progressViewStyle(ProgressBarStyle(color: status.color, withOverlay: true))
                            .frame(width: geometry.frame(in: .local).size.width * percent - spacing)
                    } else { // i > currentSegment
                        ProgressView(value: 0.0)
                            .progressViewStyle(ProgressBarStyle(color: status.color, withOverlay: false))
                            .frame(width: geometry.frame(in: .local).size.width * percent - spacing)
                    }
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }

    /// Highly reliant on a work-rest...work-rest-longbreak sequence
    func getStatus(for index: Int) -> PomoStatus {
        if index == segmentCount-2 { // -2 to take off ".end" segment
            return .longBreak
        } else if index % 2 == 0 {
            return .work
        } else {
            return .rest
        }
    }

    /// This function makes assumptions about the sequence
    func getPercent(for status: PomoStatus) -> Double {
        switch status {
        case .work:
            return workDuration / totalTime
        case .rest:
            return restDuration / totalTime
        case .longBreak:
            return breakDuration / totalTime
        case .end:
            return 0.0
        }
    }

    /// This property makes assumptions about the sequence
    private var totalTime: Double {
        let count = Double(segmentCount - 2) / 2  // -2 to take off ".end" segment

        return workDuration * count + restDuration * count + breakDuration
    }
}

struct ProgressBarStyle: ProgressViewStyle {
    var color: Color = .pink
    var height: CGFloat = 4.0
    var withOverlay: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        // fractionCompleted doesn't work for timerInterval ProgressViews
        // so customization is limited
        ProgressView(configuration)
            .tint(color).brightness(0.1)
            .labelsHidden()
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .frame(height: 5)
                    .foregroundStyle(
                        LinearGradient(colors: [.clear, .white], startPoint: .leading, endPoint: .trailing)
                            .blendMode(.softLight)
                            .opacity(0.3)
                    )
                    .opacity(withOverlay ? 1.0 : 0.0)
            }
            .background(
                color.opacity(0.4)
                    .clipShape(Capsule())
                    .frame(height: height)
            )
            .frame(height: height)
    }
}

#Preview {
    ZStack {
        RoundedRectangle(cornerRadius: 10)
            .fill(.tertiary)
            .frame(height: 100)
            .opacity(0.4)
        WidgetProgressBar(timerInterval: Date.now...Date.now.addingTimeInterval(5),
                          currentSegment: 2,
                          segmentCount: 5,
                          pausedAt: nil,
                          workDuration: PomoTimer.defaultWorkTime,
                          restDuration: PomoTimer.defaultRestTime,
                          breakDuration: PomoTimer.defaultBreakTime)
        .padding()
    }
    .padding()
}
