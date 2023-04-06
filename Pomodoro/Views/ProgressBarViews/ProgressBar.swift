//
//  ProgressBar.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/22.
//

import Foundation
import SwiftUI

struct ProgressBar: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var pomoTimer: PomoTimer
    
    var metrics: GeometryProxy
    
    @StateObject var taskNotes = TasksOnBar()
    @ObservedObject var taskFromAdder: DraggableTask
    
    @State var dragValue = 0.0
    @State var isDragging = false
    @State var dragStarted = false
    
    private let barPadding: Double = 16.0
    private let barOutlinePadding: Double = 2.0
    private let barHeight: Double = 16.0
    
    var body: some View {
        TimeLineColorBars()
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
                if newPhase == .active {
                    taskNotes.restoreFromUserDefaults()
                } else if newPhase == .inactive {
                    taskNotes.saveToUserDefaults()
                }
            }
    }
    
    @ViewBuilder
    private func TimeLineColorBars() -> some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            VStack (spacing: 0) {
                HStack {
                    Text("progress")
                        .font(.system(size: 15, design: .monospaced))
                        .opacity(0)
                    Spacer()
                    Text("\(Int(pomoTimer.getProgress(atDate: context.date) * 100))%")
                        .font(.system(size: 15, design: .monospaced))
                }
                .padding(.bottom, 8)
                
                ZStack {
                    Group {
                        ColorBars(isMask: false)
                            .accessibilityIdentifier("DraggableProgressBar")
                            .mask { RoundedRectangle(cornerRadius: 7) }
                        ProgressIndicator(at: context.date)
                            .opacity(shouldShowProgressIndicator(at: context.date) ? 1.0 : 0.0)
                            .allowsHitTesting(false)
                            
                    }
                    .gesture(drag)
                    
                    TasksView(at: context.date)
                    
                    BreakTimeLabel(at: context.date)
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
    private func ColorBars(isMask: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                GeometryReader { geometry in
                    let status = pomoTimer.order[i].getStatus()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .position(x: geometry.size.width/2, y: geometry.size.height/2)
                        .scaleEffect(x: 2.0, anchor: .trailing)
                        .shadow(radius: 5)
                        .foregroundStyle(getColorForStatus(status))
                        .brightness(i<taskNotes.pomoHighlight.count && taskNotes.pomoHighlight[i] ? 0.18 : 0.0)
                    
                        .onChange(of: taskFromAdder.dragHasEnded) { _ in
                            guard taskFromAdder.dragHasEnded && taskFromAdder.dragLocation != nil && !isMask else { return }
                            taskNotes.pomoHighlight[i] = false
                                    
                            let taskDragLocation = taskFromAdder.dragLocation!.adjusted(for: metrics)
                            let dropRect = getDropRect(geometry: geometry)
                            
                            if taskDragLocation.within(rect: dropRect) {
                                if i < taskNotes.tasksOnBar.count {
                                    taskNotes.addTask(taskFromAdder.dragText, index: i, context: viewContext)
                                    taskFromAdder.dragText = ""
                                }
                                resetHaptic()
                            }
                        }
                    
                        .onChange(of: taskFromAdder.dragLocation) { _ in
                            guard taskFromAdder.dragLocation != nil && !isMask else { return }
                            
                            let taskDragLocation = taskFromAdder.dragLocation!.adjusted(for: metrics)
                            let dropRect = getDropRect(geometry: geometry)
                            if taskDragLocation.within(rect: dropRect) {
                                if status == .work {
                                    if !taskNotes.pomoHighlight[i] { basicHaptic() }
                                    taskNotes.pomoHighlight[i] = true
                                }
                            } else {
                                taskNotes.pomoHighlight[i] = false
                            }
                        }
                }
                .frame(width: getBarWidth() * getProportion(i) - barOutlinePadding, height: barHeight)
                .padding(.horizontal, 1)
                .zIndex(Double(pomoTimer.order.count - i))
            }
        }
    }
    
    private func getDropRect(geometry: GeometryProxy) -> CGRect {
        var rect: CGRect = geometry.frame(in: .global)
        rect.origin.y -= 50
        rect.size.height += 100
        return rect
    }
    
    
    @ViewBuilder
    private func ProgressIndicator(at date: Date) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Rectangle().fill(.clear).frame(width: 1, height: barHeight).overlay (
                AnimatedImage(imageNames: (1...10).map { "PickIndicator\($0)" }, interval: 0.2, loops: true)
                    .scaleEffect(50)
                    .opacity(0.7)
            )
            
            Rectangle()
                .foregroundColor(colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.5))
                .blendMode(colorScheme == .dark ? .colorBurn : .colorDodge)
                .frame(width: getBarWidth() * (1 - pomoTimer.getProgress(atDate: date)), height: barHeight)
        }
        .mask { RoundedRectangle(cornerRadius: 7) }
    }
    
    private func shouldShowProgressIndicator(at date: Date) -> Bool {
        return pomoTimer.getProgress(atDate: date) != 0.0 || !pomoTimer.isPaused || isDragging
    }
    
    
    @ViewBuilder
    private func TasksView(at date: Date) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<pomoTimer.order.count, id: \.self) { i in
                ZStack (alignment: .leading) {
                    let status = pomoTimer.order[i].getStatus()
                    
                    if status == .work {
                        TaskLabel(index: i, taskNotes: taskNotes,
                                  taskFromAdder: taskFromAdder,
                                  pomoTimer: pomoTimer)
                    }
                }
                .frame(width: getBarWidth() * getProportion(i) - barOutlinePadding, height: barHeight)
                .padding(.horizontal, 1)
            }
        }
    }
    
    @ViewBuilder
    private func BreakTimeLabel(at date: Date) -> some View {
        let i = pomoTimer.order.count - 1
        HStack(spacing: 0) {
            Spacer()
            
            ZStack {
                let breakDate = date.addingTimeInterval(pomoTimer.timeRemaining(for: i-1, atDate: date))
                AngledText(text: timeFormatter.string(from: breakDate))
                    .id("BreakTime")
                    .scaleEffect(0.85)
                    .offset(x: -(getBarWidth() * getProportion(i) - barOutlinePadding)/2 + 3)
                    .opacity(0.6)
            }
            .frame(width: getBarWidth() * getProportion(i) - barOutlinePadding, height: barHeight)
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
    
    
    private func getProportion(_ index: Int) -> Double {
        let intervals = pomoTimer.order.map { $0.getTime() }
        let total = intervals.reduce(0, +)
        return intervals[index] / total
    }
    
    
    private func getColorForStatus(_ status: PomoStatus) -> LinearGradient {
        switch status {
        case .work:
            return LinearGradient(stops: [.init(color: Color("BarWork"), location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        case .rest:
            return LinearGradient(stops: [.init(color: Color("BarRest"), location: 0.2),
                                          .init(color: Color(hex: 0xE8BEB1), location: 1.0)],
                                  startPoint: .leading, endPoint: .trailing)
        case .longBreak:
            return LinearGradient(stops: [.init(color: Color("BarLongBreak"), location: 0.5),
                                          .init(color: Color(hex: 0xF5E1E1), location: 1.3)],
                                  startPoint: .leading, endPoint: .trailing)
        case .end:
            return LinearGradient(stops: [.init(color: Color("End"), location: 0.5),
                                          .init(color: Color(hex: 0xD3EDDD), location: 1.1)],
                                  startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private func getBarWidth() -> Double {
        return metrics.size.width - barPadding*2 - barOutlinePadding*2
    }
}


fileprivate let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
}()
