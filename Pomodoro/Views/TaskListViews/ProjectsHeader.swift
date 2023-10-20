//
//  ProjectsHeader.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/19/23.
//

import SwiftUI

struct ProjectsHeader: View {
    var body: some View {
        HStack {
            Text("Projects")
                .textCase(.uppercase)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
