//
//  ChartsPage.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/5/24.
//

import SwiftUI
import Charts

struct ChartsPage: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var pomoTimer: PomoTimer

    @FetchRequest(fetchRequest: CumulativeTimeData.pastCumulativeTimeRequest)
    var cumulativeTimes: FetchedResults<CumulativeTime>
    
    @State var showingCumulativeTimesDetails = false
    @State var showingPomodoroEstimationsDetails = false

    var borderBrightness: Double { colorScheme == .dark ? -0.09 : 0.0 }
    var borderSaturation: Double { colorScheme == .dark ? 0.85 : 1.05 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.25 : 0.4 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }
    var backgroundOpacity: Double { colorScheme == .dark ? 0.8 : 0.6 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    cumulativeTimesCard
                    pomodoroEstimationsCard
                    tasksCompletedCard
                }
                .padding()
                .fontDesign(.rounded)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(Color.background)
            .navigationTitle("Charts")
        }
    }

    @ViewBuilder var cumulativeTimesCard: some View {
        Button(action: {
            showingCumulativeTimesDetails = true
        }) {
            chartCard(color: .grayedOut) {
                Text("Cumulative Times")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.tomato)
                    .brightness(colorScheme == .dark ? 0.1 : 0.0)
                    .fixedSize()
            } latestData: {
                let average = CumulativeTimeData.thisWeeksAverages(context: viewContext)
                    .reduce(0, { $0 + $1.value })
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f hr", average / 3600))
                        .font(.title)
                        .fontWeight(.medium)
                    Text("avg this week")
                        .foregroundStyle(.secondary)
                }
                .fixedSize()
            } miniChart: {
                if #available(iOS 17, *) {
                    CumulativeTimesMiniChart()
                        .frame(width: 140)
                } else {
                    EmptyView()
                }
            }
        }
        .tint(.primary)
        .navigationDestination(isPresented: $showingCumulativeTimesDetails) {
            if #available(iOS 17, *) {
                CumulativeTimesDetails()
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder var pomodoroEstimationsCard: some View {
        Button(action: {
            showingPomodoroEstimationsDetails = true
        }) {
            chartCard(color: .grayedOut) {
                Text("Pomodoro Estimations")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.barLongBreak)
                    .brightness(colorScheme == .dark ? 0.1 : 0.0)
            } latestData: {
                Text("Data : 3.5")
            } miniChart: {
                Text("mini")
            }
        }
        .tint(.primary)
        .navigationDestination(isPresented: $showingPomodoroEstimationsDetails) {
            if #available(iOS 17, *) {
                PomodoroEstimationsDetails()
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder var tasksCompletedCard: some View {
        Button(action: {
            
        }) {
            chartCard(color: .grayedOut) {
                Text("Tasks Completed")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.end)
                    .brightness(colorScheme == .dark ? 0.1 : 0.0)
            } latestData: {
                Text("Data : 3.5")
            } miniChart: {
                Text("mini")
            }
        }
        .tint(.primary)
    }

    @ViewBuilder
    private func chartCard(color: Color,
                           @ViewBuilder title: () -> some View,
                           @ViewBuilder latestData: () -> some View,
                           @ViewBuilder miniChart: () -> some View) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    title()
                    Spacer()
                }
                Spacer()
                latestData()
            }
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                Spacer()
                miniChart()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.gradient)
                .rotationEffect(.degrees(180))
                .brightness(backgroundBrightness)
                .saturation(backgroundSaturation)
                .opacity(backgroundOpacity)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(color.gradient, lineWidth: 2)
                        .rotationEffect(.degrees(180))
                        .brightness(borderBrightness)
                        .saturation(borderSaturation)
                )
        )
    }

    @ViewBuilder var cumulativeTimesList: some View {
        if #available(iOS 17, *) {
            CumulativeTimesDetails()
        } else {
            EmptyView()
        }
    }

    @ViewBuilder var straightList: some View {
        ForEach(cumulativeTimes) { time in
            VStack(alignment: .leading, spacing: 10) {
                Text(time.hourTimestamp?.formatted() ?? "nil")
                    .foregroundStyle(.secondary)
                HStack {
                    Text(String(format: "%.2f", time.work/60))
                        .foregroundStyle(.barWork)
                    Spacer()
                    Text(String(format: "%.2f", time.rest/60))
                        .foregroundStyle(.barRest)
                    Spacer()
                    Text(String(format: "%.2f", time.longBreak/60))
                        .foregroundStyle(.barLongBreak)
                }
                .brightness(0.2)
            }
        }
        .onDelete(perform: delete)
    }

    func delete(at offsets: IndexSet) {
        for i in offsets {
            CumulativeTimeData.delete(cumulativeTimes[i], context: viewContext)
        }
    }
}

#Preview {
    ChartsPage()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(PomoTimer())
}
