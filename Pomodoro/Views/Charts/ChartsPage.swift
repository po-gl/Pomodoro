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
    @EnvironmentObject var pomoTimer: PomoTimer

    @FetchRequest(fetchRequest: CumulativeTimeData.pastCumulativeTimeRequest)
    var cumulativeTimes: FetchedResults<CumulativeTime>

    var body: some View {
        NavigationStack {
            Group {
                if !cumulativeTimes.isEmpty {
                    cumulativeTimesList
                } else {
                    Text("No data to show yet.")
                }
            }
//            .toolbar {
//                EditButton()
//                    .disabled(cumulativeTimes.isEmpty)
//            }
        }
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
