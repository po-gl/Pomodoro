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

    var body: some View {
        timeLineColorBars
            .onChange(of: pomoTimer.isPaused) { _ in
                isDragging = false
            }
            .onChange(of: pomoTimer.getStatus()) { _ in
                if isDragging {
                    basicHaptic()
                }
            }
            .onAppear {
                taskNotes.setTaskAmount(for: pomoTimer)
            }
            .onChange(of: pomoTimer.order.count) { _ in
                taskNotes.setTaskAmount(for: pomoTimer)
            }

            .onChange(of: scenePhase) { newPhase in
                guard !isOnBoarding else { return }
                if newPhase == .active {
                    taskNotes.restoreFromUserDefaults()
                    taskNotes.setTaskAmount(for: pomoTimer)
                } else if newPhase == .inactive {
                    taskNotes.saveToUserDefaults()
                }
            }
    }

    @ViewBuilder private var timeLineColorBars: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: pomoTimer.isPaused ? 60.0 : 1.0)) { context in
            VStack(spacing: 0) {
                if showsLabels {
                    HStack {
                        Spacer()
                        Text("\(Int(pomoTimer.getProgress(atDate: context.date) * 100))%")
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    .padding(.bottom, 8)
                }

                ZStack {
                    Group {
                        colorBars(isMask: false)
                            .accessibilityIdentifier("DraggableProgressBar")
                            .mask { RoundedRectangle(cornerRadius: 7) }
                        if showsLabels {
                            progressIndicator(at: context.date)
                                .opacity(shouldShowProgressIndicator(at: context.date) ? 1.0 : 0.0)
                                .allowsHitTesting(false)
                        }

                    }
                    .gesture(drag)

                    if showsLabels {
                        tasksView(at: context.date)
                        
                        breakTimeLabel(at: context.date)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, barOutlinePadding)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(colorScheme == .dark ? .black : .black)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func colorBars(isMask: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                GeometryReader { geometry in
                    let status = pomoTimer.order[i].getStatus()

                    if i < taskNotes.draggableTasksOnBar.count {
                        RoundedRectangle(cornerRadius: 4)
                            .position(x: geometry.size.width/2, y: geometry.size.height/2)
                            .scaleEffect(x: 2.0, anchor: .trailing)
                            .shadow(radius: 5)
                            .foregroundStyle(ProgressBar.getGradient(for: status))
                            .brightness(i<taskNotes.pomoHighlight.count && taskNotes.pomoHighlight[i] ? 0.18 : 0.0)

                            .onChange(of: taskFromAdder.dragHasEnded) { _ in
                                guard taskFromAdder.dragHasEnded
                                        && taskFromAdder.location != nil
                                        && !isMask else { return }
                                guard status == .work else { return }
                                taskNotes.pomoHighlight[i] = false
                                addTaskToTaskNotesIfWithinDropRect(for: i,
                                                                   draggableTask: &taskFromAdder,
                                                                   adjustedForAdder: true,
                                                                   geometry: geometry)
                            }

                            .onChange(of: taskFromAdder.location) { _ in
                                guard taskFromAdder.location != nil && !isMask else { return }
                                guard status == .work else { return }
                                updateTaskNoteHighlights(for: i,
                                                         draggableTask: taskFromAdder,
                                                         adjusted: true,
                                                         geometry: geometry)
                            }

                            .onChange(of: taskNotes.draggableTasksOnBar) { _ in
                                guard !isMask else { return }
                                guard status == .work else { return }

                                let allDragsHaveEnded = taskNotes.draggableTasksOnBar
                                    .allSatisfy { draggable in draggable.dragHasEnded }

                                for (j, draggableTask) in taskNotes.draggableTasksOnBar.enumerated() {

                                    guard draggableTask.location != nil else { continue }
                                    updateTaskNoteHighlights(for: i, from: j,
                                                             draggableTask: draggableTask,
                                                             adjusted: false,
                                                             geometry: geometry)

                                    guard allDragsHaveEnded else { continue }
                                    taskNotes.pomoHighlight[i] = false
                                    addTaskToTaskNotesIfWithinDropRect(for: i, from: j,
                                                                       draggableTask: &taskNotes.draggableTasksOnBar[j],
                                                                       adjustedForAdder: false,
                                                                       geometry: geometry)
                                }
                            }
                    }
                }
                .frame(width: max(getBarWidth() * getProportion(i) - barOutlinePadding, 0), height: barHeight)
                .padding(.horizontal, 1)
                .zIndex(Double(pomoTimer.order.count - i))
            }
        }
    }

    @ViewBuilder
    private func progressIndicator(at date: Date) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            Rectangle()
                .foregroundColor(colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.5))
                .blendMode(colorScheme == .dark ? .colorBurn : .colorDodge)
                .frame(width: max(getBarWidth() * (1 - pomoTimer.getProgress(atDate: date)), 0), height: barHeight)
                .overlay(alignment: .leading) {
                    Rectangle().fill(.clear).frame(width: 1, height: barHeight).overlay(
                        AnimatedImage(data: Animations.pickIndicator)
                        .scaleEffect(50)
                        .opacity(0.7)
                    )
                }
        }
        .mask { RoundedRectangle(cornerRadius: 7) }
    }

    private func shouldShowProgressIndicator(at date: Date) -> Bool {
        return pomoTimer.getProgress(atDate: date) != 0.0 || !pomoTimer.isPaused || isDragging
    }

    @ViewBuilder
    private func tasksView(at date: Date) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                ZStack(alignment: .leading) {
                    let status = pomoTimer.order[i].getStatus()

                    if status == .work {
                        if i < taskNotes.draggableTasksOnBar.count {
                            TaskLabel(index: i, taskNotes: taskNotes,
                                      taskFromAdder: taskFromAdder,
                                      draggableTask: $taskNotes.draggableTasksOnBar[i],
                                      peekOffset: peekOffset)
                        }
                    }
                }
                .frame(width: max(getBarWidth() * getProportion(i) - barOutlinePadding, 0), height: barHeight)
                .padding(.horizontal, 1)
            }
        }
    }

    @ViewBuilder
    private func breakTimeLabel(at date: Date) -> some View {
        let i = pomoTimer.order.count - 1
        HStack(spacing: 0) {
            Spacer()

            ZStack {
                let breakDate = pomoTimer.status == .longBreak ?
                date.addingTimeInterval(-(pomoTimer.getDuration(for: .longBreak) - pomoTimer.timeRemaining(for: i, atDate: date))) :
                date.addingTimeInterval(pomoTimer.timeRemaining(for: i-1, atDate: date))
                AngledText(text: pomoTimer.status == .end ? " --:--" : timeFormatter.string(from: breakDate))
                    .id("BreakTime")
                    .scaleEffect(0.85)
                    .offset(x: -(getBarWidth() * getProportion(i) - barOutlinePadding)/2 + 3)
                    .opacity(0.6)
                    .environment(\.isOnBoarding, false)
            }
            .frame(width: max(getBarWidth() * getProportion(i) - barOutlinePadding, 0), height: barHeight)
            .padding(.horizontal, 1)
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
            .onChanged { event in
                guard pomoTimer.isPaused || pomoTimer.getStatus() == .end else { return }
                if !dragStarted { heavyHaptic() }

                isDragging = true; dragStarted = true
                let padding = barPadding + barOutlinePadding

                var x = event.location.x.rounded()
                x = x.clamped(to: padding...metrics.size.width - padding)
                x -= padding

                let percent = x / getBarWidth()
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

    private func addTaskToTaskNotesIfWithinDropRect(for i: Int, from j: Int = 0,
                                                    draggableTask: inout DraggableTask,
                                                    adjustedForAdder: Bool,
                                                    geometry: GeometryProxy) {
        if isWithinDropRect(draggableTask, adjusted: adjustedForAdder, geometry: geometry) {
            guard i < taskNotes.tasksOnBar.count && j < taskNotes.tasksOnBar.count else { return }
            if taskNotes.tasksOnBar[i] != draggableTask.text {
                if adjustedForAdder {
                    taskNotes.addTask(draggableTask.text, index: i, context: viewContext)
                    draggableTask.text = ""
                } else {
                    let swapTask = taskNotes.tasksOnBar[i]
                    taskNotes.addTask(swapTask, index: j, context: viewContext)
                    taskNotes.addTask(draggableTask.text, index: i, context: viewContext)
                    // set location to nil to prevent duplicate updates
                    draggableTask.location = nil
                }
                resetHaptic()
            }
        }
    }

    private func updateTaskNoteHighlights(for i: Int, from j: Int? = nil,
                                          draggableTask: DraggableTask,
                                          adjusted: Bool,
                                          geometry: GeometryProxy) {
        if isWithinDropRect(draggableTask, adjusted: adjusted, geometry: geometry) {
            if !taskNotes.pomoHighlight[i] {
                if i != j {
                    ThrottledHaptics.shared.basic()
                }
            }
            taskNotes.pomoHighlight[i] = true
        } else {
            taskNotes.pomoHighlight[i] = false
        }
    }

    private func isWithinDropRect(_ draggableTask: DraggableTask, adjusted: Bool, geometry: GeometryProxy) -> Bool {
        let taskDragLocation = adjusted ? draggableTask.location?.adjusted(for: metrics) ?? CGPoint()
                                        : draggableTask.location ?? CGPoint()
        let dropRect = getDropRect(geometry: geometry)
        let ret = taskDragLocation.within(rect: dropRect)
        return ret
    }

    private func getDropRect(geometry: GeometryProxy) -> CGRect {
        var rect: CGRect = geometry.frame(in: .global)
        rect.origin.y -= 50
        rect.size.height += 100
        return rect
    }

    private func getProportion(_ index: Int) -> Double {
        let intervals = pomoTimer.order.map { $0.getTime() }
        let total = intervals.reduce(0, +)
        return intervals[index] / total
    }

    static func getGradient(for status: PomoStatus) -> LinearGradient {
        switch status {
        case .work:
            return LinearGradient(stops: [.init(color: .barWork, location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        case .rest:
            return LinearGradient(stops: [.init(color: .barRest, location: 0.2),
                                          .init(color: Color(hex: 0xE8BEB1), location: 1.0)],
                                  startPoint: .leading, endPoint: .trailing)
        case .longBreak:
            return LinearGradient(stops: [.init(color: .barLongBreak, location: 0.5),
                                          .init(color: Color(hex: 0xF5E1E1), location: 1.3)],
                                  startPoint: .leading, endPoint: .trailing)
        case .end:
            return LinearGradient(stops: [.init(color: .end, location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        }
    }

    private func getBarWidth() -> Double {
        return metrics.size.width - barPadding*2 - barOutlinePadding*2
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
