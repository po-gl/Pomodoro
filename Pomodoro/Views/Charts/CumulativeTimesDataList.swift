//
//  CumulativeTimesDataList.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/11/24.
//

import SwiftUI

struct CumulativeTimesDataList: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.editMode) var editMode

    @FetchRequest(fetchRequest: CumulativeTimeData.pastCumulativeTimeRequest)
    var cumulativeTimes: FetchedResults<CumulativeTime>

    @State var showDeleteDialog = false

    var body: some View {
        List {
            ForEach(cumulativeTimes) { time in
                VStack(alignment: .leading, spacing: 10) {
                    Text(time.hourTimestamp?.formatted(.dateTime.hour().weekday().month().day().year()) ?? "nil")
                        .foregroundStyle(.secondary)
                    HStack {
                        timeLabel(duration: time.work, for: .work)
                        Spacer()
                        timeLabel(duration: time.rest, for: .rest)
                        Spacer()
                        timeLabel(duration: time.longBreak, for: .longBreak)
                    }
                    .brightness(0.2)
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Time Data")
        .toolbar {
            if editMode?.wrappedValue.isEditing == true {
                Button(role: .destructive, action: {
                    showDeleteDialog = true
                }) {
                    Text("Delete All")
                }
                .accessibilityIdentifier("deleteAllButton")
            }
            EditButton()
                .accessibilityIdentifier("editButton")
        }

        .confirmationDialog("Delete All Cumulative Times", isPresented: $showDeleteDialog) {
            Button(role: .destructive, action: {
                CumulativeTimeData.deleteAll(context: viewContext)
            }) {
                Text("Delete All Time Data")
            }
            .accessibilityIdentifier("confirmDeleteAllButton")
        } message: {
            Text("Are you sure you want to delete all cumulative times?")
        }
    }

    @ViewBuilder
    func timeLabel(duration: Double, for status: PomoStatus) -> some View {
        VStack(alignment: .leading) {
            Text(status.rawValue)
                .foregroundStyle(.secondary)
                .font(.callout)
            Text(String(format: "%.2f min", duration / 60))
                .foregroundStyle(status.color)
                .monospacedDigit()
        }
        .frame(width: 100, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
    }

    func delete(at offsets: IndexSet) {
        for i in offsets {
            CumulativeTimeData.delete(cumulativeTimes[i], context: viewContext)
        }
    }
}

#Preview {
    NavigationStack {
        CumulativeTimesDataList()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
