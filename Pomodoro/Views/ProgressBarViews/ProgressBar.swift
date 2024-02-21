//
//  ProgressBar.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/22.
//

import Foundation
import SwiftUI

// swiftlint:disable:next type_body_length
struct ProgressBar: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isOnBoarding) private var isOnBoarding

    @EnvironmentObject var pomoTimer: PomoTimer

    var metrics: GeometryProxy

    var showsLabels = true

    @EnvironmentObject var taskNotes: TasksOnBar
    @Binding var taskFromAdder: DraggableTask

    var peekOffset = CGFloat.zero

    @State var dragValue = 0.0
    @State var isDragging = false
    @State var dragStarted = false

    private let barPadding: Double = 16.0
    private let barOutlinePadding: Double = 2.0
    private let barHeight: Double = 16.0

    var barWidth: CGFloat {
        metrics.size.width - barPadding*2 - barOutlinePadding*2
    }

    var proportions: [CGFloat] {
        cachedProportions ?? calculateProportions()
    }

    @State var cachedProportions: [CGFloat]? = nil
    @State var cachedTaskRects: [CGRect]? = nil

    @State var currentHighlightedIndex: Int? = nil

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if showsLabels {
                    percentProgress
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.bottom, 8)
                }
                ZStack {
                    colorBars
                            .accessibilityIdentifier("DraggableProgressBar")
                    progressIndicator
                        .gesture(progressDragGesture)
                    if showsLabels {
                        tasksAboveBars
                        breakTimeLabel
                    }
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)

            .onAppear {
                updateCachedViewCalculations(geometry)
                taskNotes.setTaskAmount(for: pomoTimer)
            }
            .onChange(of: pomoTimer.order.count) {
                updateCachedViewCalculations(geometry)
                taskNotes.setTaskAmount(for: pomoTimer)
            }

            .onChange(of: pomoTimer.workDuration) {
                withAnimation(.bouncy) {
                    updateCachedViewCalculations(geometry)
                }
            }
            .onChange(of: pomoTimer.restDuration) {
                withAnimation(.bouncy) {
                    updateCachedViewCalculations(geometry)
                }
            }
            .onChange(of: pomoTimer.breakDuration) {
                withAnimation(.bouncy) {
                    updateCachedViewCalculations(geometry)
                }
            }

            .onChange(of: pomoTimer.isPaused) {
                isDragging = false
            }
            .onChange(of: pomoTimer.getStatus()) {
                if isDragging {
                    basicHaptic()
                }
            }

        }
        .padding(.horizontal)
    }

    func updateCachedViewCalculations(_ geometry: GeometryProxy) {
        cachedProportions = calculateProportions()
        if showsLabels {
            cachedTaskRects = calculateTaskRects(in: geometry)
        }
    }

    @ViewBuilder var percentProgress: some View {
        TimelineView(isPausedTimelineSchedule) { context in
            Text("\(Int(pomoTimer.getProgress(atDate: context.date) * 100))%")
                .font(.system(.subheadline, design: .monospaced))
        }
    }

    @ViewBuilder var breakTimeLabel: some View {
        TimelineView(isPausedTimelineSchedule) { context in
            if proportions.count >= pomoTimer.order.count {
                let i = pomoTimer.order.count - 1
                let proportion = proportions[i]
                ZStack {
                    let breakDate = pomoTimer.status == .longBreak ?
                    context.date.addingTimeInterval(-(pomoTimer.getDuration(for: .longBreak) - pomoTimer.timeRemaining(for: i, atDate: context.date))) :
                    context.date.addingTimeInterval(pomoTimer.timeRemaining(for: i-1, atDate: context.date))
                    AngledText(text: pomoTimer.status == .end ? " --:--" : timeFormatter.string(from: breakDate))
                        .id("BreakTime")
                        .scaleEffect(0.85)
                        .offset(x: -(barWidth * proportion - barOutlinePadding)/2 + 3)
                        .opacity(0.6)
                        .environment(\.isOnBoarding, false)
                }
                .frame(width: max(barWidth * proportion - barOutlinePadding, 0), height: barHeight)
                .padding(.horizontal, 1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder var colorBars: some View {
        TimelineView(isPausedTimelineSchedule) { context in
            let proportions = proportions
            if proportions.count >= pomoTimer.order.count {
                HStack(spacing: 0) {
                    ForEach(pomoTimer.order.indices, id: \.self) { i in
                        let width = max(barWidth * proportions[i] - barOutlinePadding, 0)
                        let barOverlap = 30.0
                        let barOffset = 5.0
                        VStack {
                            RoundedRectangle(cornerRadius: 7)
                                .shadow(radius: 5)
                                .foregroundStyle(pomoTimer.order[i].status.gradient())
                                .brightness(i < taskNotes.pomoHighlight.count && taskNotes.pomoHighlight[i] ? 0.18 : 0.0)
                                .frame(width: width + barOverlap)
                                .offset(x: -barOverlap / 2 + barOffset)
                                .alignmentGuide(.leading, computeValue: { dimension in
                                    dimension[.trailing] - barOverlap
                                })
                        }
                        .frame(width: width, height: barHeight)
                        .padding(.horizontal, 1)
                        .zIndex(Double(pomoTimer.order.count - i))
                    }
                }
                .frame(maxWidth: barWidth)
                .mask { RoundedRectangle(cornerRadius: 7) }
                .padding(.vertical, 2)
                .padding(.horizontal, barOutlinePadding)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.black)
                }
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder var progressIndicator: some View {
        TimelineView(isPausedTimelineSchedule) { context in
            let progress = pomoTimer.getProgress(atDate: context.date)
            Rectangle()
                .foregroundStyle(colorScheme == .dark ? .black : .white)
                .opacity(0.5)
                .blendMode(colorScheme == .dark ? .colorBurn : .colorDodge)
                .frame(width: max(barWidth * (1 - progress), 0), height: barHeight)
                .overlay(alignment: .leading) {
                    Rectangle().fill(.clear).frame(width: 1, height: barHeight).overlay(
                        AnimatedImage(data: Animations.pickIndicator)
                            .scaleEffect(50)
                            .opacity(0.7)
                    )
                }
                .opacity(progress > 0.00001 || !pomoTimer.isPaused || isDragging ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .contentShape(Rectangle())
        .mask { RoundedRectangle(cornerRadius: 7) }
    }

    @ViewBuilder var tasksAboveBars: some View {
        TimelineView(isPausedTimelineSchedule) { context in
            let proportions = proportions
            if let taskRects = cachedTaskRects, proportions.count >= pomoTimer.order.count
                && taskRects.count >= pomoTimer.order.count
                && taskNotes.draggableTasksOnBar.count >= pomoTimer.order.count {

                HStack(spacing: 0) {
                    ForEach(pomoTimer.order.indices, id: \.self) { i in
                        let width = max(barWidth * proportions[i] - barOutlinePadding, 0)
                        let status = pomoTimer.order[i].status
                        ZStack(alignment: .leading) {
                            if status == .work {
                                TaskLabel(index: i, taskNotes: taskNotes,
                                          taskFromAdder: taskFromAdder,
                                          draggableTask: $taskNotes.draggableTasksOnBar[i],
                                          peekOffset: peekOffset)
                            }
                        }
                        .frame(width: width, height: barHeight)
                        .padding(.horizontal, 1)
                    }
                }
                // Handle DraggableTask from adder
                .onChange(of: taskFromAdder) {
                    guard let location = taskFromAdder.location else { return }
                    resetPomoHighlights()
                    guard let index = calculateTaskRectIndex(containing: location, withAdjustment: true) else { return }
                    handleDraggableTask(at: index, task: &taskFromAdder)
                }
                // Handle DraggableTasks from tasks on bar
                .onChangeWithThrottle(of: taskNotes.draggableTasksOnBar, for: 0.033) { _ in
                    for fromIndex in 0..<taskNotes.draggableTasksOnBar.count {
                        guard let location = taskNotes.draggableTasksOnBar[fromIndex].location else { continue }
                        resetPomoHighlights()
                        guard let toIndex = calculateTaskRectIndex(containing: location, withAdjustment: false) else { return }
                        handleDraggableTask(at: toIndex, task: &taskNotes.draggableTasksOnBar[fromIndex], swapWith: fromIndex)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    func handleDraggableTask(at index: Int, task draggableTask: inout DraggableTask, swapWith swapIndex: Int? = nil) {
        taskNotes.pomoHighlight[index] = true
        if index != currentHighlightedIndex {
            ThrottledHaptics.shared.basic()
            currentHighlightedIndex = index
        }

        if draggableTask.dragHasEnded {
            resetHaptic()
            resetPomoHighlights()

            if let swapIndex {
                guard swapIndex != index else { return }
                let swapTask = taskNotes.tasksOnBar[index]
                taskNotes.addTask(swapTask, index: swapIndex, context: viewContext)
            }

            taskNotes.addTask(draggableTask.text, index: index, context: viewContext)
            draggableTask.text = ""
            // set location to nil to prevent duplicate updates
            draggableTask.location = nil
        }
    }

    func calculateProportions() -> [CGFloat] {
        let intervals = pomoTimer.order.map { $0.timeInterval }
        let total = intervals.reduce(0, +)
        let proportions: [CGFloat] = intervals.map { $0 / total }
        let padding: [CGFloat] = Array(repeating: 0.0, count: pomoTimer.maxOrder - proportions.count)
        return proportions + padding
    }

    func calculateTaskRects(in geometry: GeometryProxy) -> [CGRect] {
        let proportions = calculateProportions()
        let geoRect = geometry.frame(in: .global)
        var rects = [CGRect]()

        let height = geometry.size.height + 100
        let yPos = geoRect.origin.y - 60
        var xPos = geoRect.origin.x
        for proportion in proportions {
            let width = proportion * geoRect.size.width

            let rect = CGRect(x: xPos, y: yPos, width: width, height: height)
            rects.append(rect)
            xPos += width
        } 
        return rects
    }

    func calculateTaskRectIndex(containing point: CGPoint, withAdjustment: Bool) -> Int? {
        guard let taskRects = cachedTaskRects else { return nil }
        guard taskRects.count >= pomoTimer.order.count else { return nil }
        let point = withAdjustment ? point.adjusted(for: metrics) : point

        for i in 0..<pomoTimer.order.count {
            guard pomoTimer.order[i].status == .work else { continue }
            if point.within(rect: taskRects[i]) {
                return i
            }
        }
        return nil
    }

    func resetPomoHighlights() {
        for i in 0..<taskNotes.pomoHighlight.count {
            taskNotes.pomoHighlight[i] = false
        }
    }

    var isPausedTimelineSchedule: PeriodicTimelineSchedule {
        PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)
    }

    private var progressDragGesture: some Gesture {
        DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
            .onChanged { event in
                guard pomoTimer.isPaused || pomoTimer.getStatus() == .end else { return }
                if !dragStarted { heavyHaptic() }

                isDragging = true; dragStarted = true
                let padding = barPadding + barOutlinePadding

                var x = event.location.x.rounded()
                x = x.clamped(to: padding...metrics.size.width - padding)
                x -= padding

                let percent = x / barWidth
                pomoTimer.setPercentage(to: percent)
            }
            .onEnded { _ in
                dragStarted = false
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation { isDragging = false }
                }
            }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
