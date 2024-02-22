//
//  LightweightTaskCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/27/24.
//

import SwiftUI

struct LightweightTaskCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.refreshInfo) private var refreshInfo

    @ObservedObject var taskItem: TaskNote

    var showNotes = true

    var todaysTasks: FetchedResults<TaskNote>? = nil

    @State var showTaskInfo = false

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            TaskCheck(taskItem: taskItem, isAdderCell: false, todaysTasks: todaysTasks)
            Group {
                VStack(spacing: 5) {
                    mainText
                    if showNotes && !(taskItem.note?.isEmpty ?? true) {
                        noteText
                    }
                }
                TaskInfoCluster(taskItem: taskItem, showTaskInfo: $showTaskInfo)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { showTaskInfo = true }
            }
        }
        .sheet(isPresented: $showTaskInfo) {
            TaskInfoView(taskItem: taskItem)
        }
        .onChange(of: showTaskInfo) {
            if !showTaskInfo {
                refreshInfo()
            }
        }
    }

    var mainText: some View {
        HStack {
            Text(taskItem.text ?? "")
                .accessibilityIdentifier("\(taskItem.text ?? "")LightweightCell")
                .multilineTextAlignment(.leading)
                .foregroundStyle(taskItem.timestamp?.isToday() ?? true ? .primary : .secondary)
            Spacer()
        }
    }

    var noteText: some View {
        HStack {
            Text(taskItem.note ?? "")
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
