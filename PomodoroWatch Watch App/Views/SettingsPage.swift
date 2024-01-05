//
//  SettingsPage.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/4/24.
//

import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject var pomoTimer: PomoTimer

    let geometry: GeometryProxy

    @AppStorage("workDuration", store: UserDefaults.pomo) var workDuration: TimeInterval = PomoTimer.defaultWorkTime
    @AppStorage("restDuration", store: UserDefaults.pomo) var restDuration: TimeInterval = PomoTimer.defaultRestTime
    @AppStorage("breakDuration", store: UserDefaults.pomo) var breakDuration: TimeInterval = PomoTimer.defaultBreakTime

    @StateObject var buddySelection = BuddySelection.shared
    @AppStorage("enableBuddies", store: UserDefaults.pomo) var enableBuddies = true

    var body: some View {
        if #available(watchOS 10, *) {
            TabView {
                ChangerPage()
                NavigationStack {
                    durationsSettings
                        .navigationTitle("Durations")
                }
                NavigationStack {
                    buddySettings(geometry)
                        .navigationTitle("Buddy Selection")
                }
            }
            .tabViewStyle(.verticalPage)
        } else {
            ScrollView {
                ChangerPage()
                Divider()
                    .padding(.vertical, 15)
                durationsSettings
                Divider()
                    .padding(.vertical, 15)
                buddySettings(geometry)
            }
        }
    }
    
    @ViewBuilder var durationsSettings: some View {
        ScrollView {
            VStack(spacing: 15) {
                durationSlider("Work", value: Binding(get: { self.workDuration }, set: { newValue in
                    self.workDuration = newValue
                    resetDurations()
                }), in: 60*5...60*40)
                .tint(Color("BarWork"))
                durationSlider("Rest", value: Binding(get: { self.restDuration }, set: { newValue in
                    self.restDuration = newValue
                    resetDurations()
                }), in: 60*5...60*30)
                .tint(Color("BarRest"))
                durationSlider("Break", value: Binding(get: { self.breakDuration }, set: { newValue in
                    self.breakDuration = newValue
                    resetDurations()
                }), in: 60*10...60*60)
                .tint(Color("BarLongBreak"))

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
                .tint(Color("End"))
                .onAppear {
                    workDuration = pomoTimer.workDuration
                    restDuration = pomoTimer.restDuration
                    breakDuration = pomoTimer.breakDuration
                }
            }
        }
    }

    @ViewBuilder
    func durationSlider(_ text: String,
                        value: Binding<TimeInterval>,
                        in range: ClosedRange<TimeInterval>) -> some View {
        VStack {
            HStack(spacing: 5) {
                Text(text)
                Spacer()
                Text(value.wrappedValue.compactTimerFormatted())
                    .monospacedDigit()
                    .fontWeight(.medium)
            }
            Slider(value: value, in: range, step: 60*5)
            .labelStyle(.titleAndIcon)
        }
    }

    func resetDurations() {
        pomoTimer.reset(pomos: pomoTimer.pomoCount,
                        work: workDuration,
                        rest: restDuration,
                        longBreak: breakDuration)
    }

    @ViewBuilder
    func buddySettings(_ geometry: GeometryProxy) -> some View {
        let selectorWidth = geometry.size.width/2 - 10
        ScrollView {
            VStack(spacing: 10) {
                Toggle(isOn: $enableBuddies, label: {
                    Text("Pixel Buddies")
                })
                .tint(Color("End"))
                .padding(.horizontal, 10)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 11).fill(.tertiary).opacity(0.5))
                HStack {
                    Spacer()
                    buddySelectorWithAction(.tomato, size: CGSize(width: selectorWidth, height: selectorWidth))
                    Spacer()
                    buddySelectorWithAction(.blueberry, size: CGSize(width: selectorWidth, height: selectorWidth))
                    Spacer()
                }
                HStack {
                    Spacer()
                    buddySelectorWithAction(.banana, size: CGSize(width: selectorWidth, height: selectorWidth))
                    Spacer()
                    Rectangle().opacity(0).frame(width: selectorWidth)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    func buddySelectorWithAction(_ buddy: Buddy, size: CGSize) -> some View {
        BuddySelector(buddy: buddy,
                      isSelected: buddySelection.selection[buddy, default: false],
                      size: size,
                      font: .footnote)
            .saturation(enableBuddies ? 1.0 : 0.3)
            .onTapGesture {
                basicHaptic()
                buddySelection.toggle(buddy)
                if buddySelection.selection[buddy, default: false] {
                    enableBuddies = true
                }
            }
    }
}

struct SettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        let pomoTimer = PomoTimer()
        return GeometryReader { geometry in
            if #available(watchOS 10, *) {
                TabView {
                    SettingsPage(geometry: geometry)
                        .containerBackground(Color("BarWork").gradient.opacity(0.4), for: .tabView)
                        .environmentObject(pomoTimer)
                }
            } else {
                SettingsPage(geometry: geometry)
                    .environmentObject(pomoTimer)
            }
        }
    }
}
