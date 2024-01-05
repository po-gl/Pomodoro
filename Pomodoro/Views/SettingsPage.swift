//
//  SettingsPage.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/2/24.
//

import SwiftUI


struct SettingsPage: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var pomoTimer: PomoTimer

    @AppStorage("workDuration", store: UserDefaults.pomo) var workDuration: TimeInterval = PomoTimer.defaultWorkTime
    @AppStorage("restDuration", store: UserDefaults.pomo) var restDuration: TimeInterval = PomoTimer.defaultRestTime
    @AppStorage("breakDuration", store: UserDefaults.pomo) var breakDuration: TimeInterval = PomoTimer.defaultBreakTime
    
    @StateObject var buddySelection = BuddySelection.shared
    @AppStorage("enableBuddies", store: UserDefaults.pomo) var enableBuddies = true

    @State var draggableTaskStub = DraggableTask()
    let durationChangeAnim: Animation = .interpolatingSpring(stiffness: 190, damping: 13)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    GeometryReader { geometry in
                        ZStack {
                            ProgressBar(metrics: geometry, showsLabels: false, taskFromAdder: $draggableTaskStub)
                                .disabled(true)
                            BuddyView(metrics: geometry)
                                .offset(y: -20)
                                .brightness(colorScheme == .dark ? 0.0 : 0.1)
                        }
                        .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    }
                    .frame(height: 25)

                    GroupBox {
                        durationSlider("Work Duration", value: $workDuration, in: 60*5...60*40)
                            .tint(Color("BarWork"))
                    }
                    GroupBox {
                        durationSlider("Rest Duration", value: $restDuration, in: 60*3...60*30)
                            .tint(Color("BarRest"))
                    }
                    GroupBox {
                        durationSlider("Long Break Duration", value: $breakDuration, in: 60*10...60*60)
                            .tint(Color("BarLongBreak"))
                    }
                    HStack {
                        Spacer()
                        Button(action: {
                            resetHaptic()
                            withAnimation {
                                workDuration = PomoTimer.defaultWorkTime
                                restDuration = PomoTimer.defaultRestTime
                                breakDuration = PomoTimer.defaultBreakTime
                                pomoTimer.reset(pomos: pomoTimer.pomoCount,
                                                work: workDuration,
                                                rest: restDuration,
                                                longBreak: breakDuration)
                            }
                        }) {
                            Text("Reset to default settings")
                                .font(.callout)
                        }
                    }
                    .padding(.horizontal)
                    Divider()
                        .padding(.vertical, 5)
                    GroupBox {
                        buddySelectors
                        Divider()
                            .padding(.vertical, 5)
                        Toggle(isOn: $enableBuddies, label: {
                            Text("Pixel Buddies")
                        })
                        .tint(Color("End"))
                    }
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Settings")
            .onAppear {
                workDuration = pomoTimer.workDuration
                restDuration = pomoTimer.restDuration
                breakDuration = pomoTimer.breakDuration
            }
        }
    }

    @ViewBuilder var buddySelectors: some View {
        HStack {
            Spacer()
            buddySelectorWithAction(.tomato)
            Spacer()
            buddySelectorWithAction(.blueberry)
            Spacer()
            buddySelectorWithAction(.banana)
            Spacer()
        }
    }

    @ViewBuilder
    func buddySelectorWithAction(_ buddy: Buddy) -> some View {
        BuddySelector(buddy: buddy, isSelected: buddySelection.selection[buddy, default: false])
        .saturation(enableBuddies ? 1.0 : 0.3)
        .onTapGesture {
            basicHaptic()
            buddySelection.toggle(buddy)
            if buddySelection.selection[buddy, default: false] {
                enableBuddies = true
            }
        }
    }

    @ViewBuilder
    func durationSlider(_ text: String,
                        value: Binding<TimeInterval>,
                        in range: ClosedRange<TimeInterval>) -> some View {
        HStack(spacing: 5) {
            Text(text)
            Spacer()
            Text(value.wrappedValue.compactTimerFormatted())
                .monospacedDigit()
                .fontWeight(.medium)
        }
        Slider(value: value, in: range, step: 60, onEditingChanged: { isEditing in
            if !isEditing {
                withAnimation(durationChangeAnim) {
                    pomoTimer.reset(pomos: pomoTimer.pomoCount,
                                    work: workDuration,
                                    rest: restDuration,
                                    longBreak: breakDuration)
                }
            }
        })
            .labelStyle(.titleAndIcon)
    }
}

#Preview {
    SettingsPage()
        .environmentObject(PomoTimer())
        .environmentObject(TasksOnBar())
}
