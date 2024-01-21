//
//  TodaysTasksHeader.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/18/23.
//

import SwiftUI

struct TodaysTasksHeader: View {
    var body: some View {
        HStack {
            Text("Today's Tasks")
                .textCase(.uppercase)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
