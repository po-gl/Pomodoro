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

    @State var showingCumulativeTimesDetails = false
    @State var showingPomodoroEstimationsDetails = false
    @State var showingCompletedDetails = false

    @State var miniChartRefresh = UUID()

    var borderBrightness: Double { colorScheme == .dark ? -0.09 : 0.0 }
    var borderSaturation: Double { colorScheme == .dark ? 0.85 : 1.05 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.25 : 0.65 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }
    var backgroundOpacity: Double { colorScheme == .dark ? 0.8 : 0.6 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pomodoroEstimationsCard
                    cumulativeTimesCard
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
        .onAppear {
            miniChartRefresh = UUID()
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
                        .monospacedDigit()
                    Text("avg this week")
                        .foregroundStyle(.secondary)
                }
                .fixedSize()
            } miniChart: {
                CumulativeTimesMiniChart()
                    .frame(width: 140)
                    .id(miniChartRefresh.uuidString + "CumulativeTimes")
            }
        }
        .accessibilityIdentifier("cumulativeTimesCard")
        .tint(.primary)
        .navigationDestination(isPresented: $showingCumulativeTimesDetails) {
            CumulativeTimesDetails()
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
                    .brightness(colorScheme == .dark ? 0.1 : -0.05)
                    .saturation(colorScheme == .dark ? 1.0 : 1.2)
                    .fixedSize()
            } latestData: {
                let averages = TasksData.thisWeeksEstimateAverages(context: viewContext)
                VStack(alignment: .leading) {
                    Text("Avg this week")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Group {
                            if let estimate = averages.estimate {
                                Text(String(format: "%.1f", estimate))
                            } else {
                                Text("--")
                            }
                        }
                        .font(.title3)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        Text("estimate")
                            .font(.callout)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Group {
                            if let actual = averages.actual {
                                Text(String(format: "%.1f", actual))
                            } else {
                                Text("--")
                            }
                        }
                        .font(.title3)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        Text("actual pomos")
                            .font(.callout)
                    }
                }
                .fixedSize()
            } miniChart: {
                PomodoroEstimationsMiniChart()
                    .frame(width: 140)
                    .id(miniChartRefresh.uuidString + "PomodoroEstimations")
            }
        }
        .accessibilityIdentifier("pomodoroEstimationsCard")
        .tint(.primary)
        .navigationDestination(isPresented: $showingPomodoroEstimationsDetails) {
            PomodoroEstimationsDetails()
        }
    }

    @ViewBuilder var tasksCompletedCard: some View {
        Button(action: {
            showingCompletedDetails = true
        }) {
            chartCard(color: .grayedOut) {
                Text("Tasks Completed")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.end)
                    .brightness(colorScheme == .dark ? 0.1 : -0.2)
                    .saturation(colorScheme == .dark ? 1.0 : 1.3)
                    .fixedSize()
            } latestData: {
                let (count, average) = TasksData.thisWeeksCompletedData(context: viewContext)
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(String(format: "%.1f", average))
                            .font(.title2)
                            .fontWeight(.medium)
                            .monospacedDigit()
                        Text("avg per day")
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(count)")
                            .font(.title2)
                            .fontWeight(.medium)
                            .monospacedDigit()
                        Text("tasks this week")
                            .foregroundStyle(.secondary)
                    }
                }
            } miniChart: {
                CompletedMiniChart()
                    .frame(width: 140)
                    .id(miniChartRefresh.uuidString + "Completed")
            }
        }
        .accessibilityIdentifier("tasksCompletedCard")
        .tint(.primary)
        .navigationDestination(isPresented: $showingCompletedDetails) {
            CompletedDetails()
        }
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
                    .foregroundStyle(color)
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
}

#Preview {
    ChartsPage()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
