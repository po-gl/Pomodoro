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
    
    var body: some View {
        let spacing: CGFloat = 3

        GeometryReader { geometry in
            HStack(spacing: spacing) {
                ForEach(0..<segmentCount, id: \.self) { i in
                    let status = getStatus(for: i)
                    let percent = getPercent(for: status)
                    if i == currentSegment {
                        ProgressView(timerInterval: timerInterval, countsDown: false)
                            .progressViewStyle(ProgressBarStyle(color: getColor(for: status)))
                            .frame(width: geometry.frame(in: .local).size.width * percent - spacing)
                    } else {
                        ProgressView(value: i < currentSegment ? 1.0 : 0.0)
                            .progressViewStyle(ProgressBarStyle(color: getColor(for: status),
                                                                withOverlay: i < currentSegment))
                            .frame(width: geometry.frame(in: .local).size.width * percent - spacing)
                    }
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }

    /// Highly reliant on a work-rest...work-rest-longbreak sequence
    func getStatus(for index: Int) -> PomoStatus {
        if index == segmentCount-1 {
            return .longBreak
        } else if index % 2 == 0 {
            return .work
        } else {
            return .rest
        }
    }

    /// This function makes assumptions about the sequence
    func getPercent(for status: PomoStatus) -> Double {
        let work = PomoTimer.defaultWorkTime
        let rest = PomoTimer.defaultRestTime
        let longBreak = PomoTimer.defaultBreakTime
        
        switch status {
        case .work:
            return work / totalTime
        case .rest:
            return rest / totalTime
        case .longBreak:
            return longBreak / totalTime
        case .end:
            return 0.0
        }
    }

    /// This property makes assumptions about the sequence
    private var totalTime: Double {
        let work = PomoTimer.defaultWorkTime
        let rest = PomoTimer.defaultRestTime
        let longBreak = PomoTimer.defaultBreakTime
        let count = Double(segmentCount - 1) / 2

        return work * count + rest * count + longBreak
    }

    func getColor(for status: PomoStatus) -> Color {
        switch status {
        case .work:
            Color("BarWork")
        case .rest:
            Color("BarRest")
        case .longBreak:
            Color("BarLongBreak")
        case .end:
            Color("End")
        }
    }
}

struct ProgressBarStyle: ProgressViewStyle {
    var color: Color = .pink
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
                          segmentCount: 5)
        .padding()
    }
    .padding()
}
