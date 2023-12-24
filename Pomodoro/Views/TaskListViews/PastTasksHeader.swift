//
//  PastTasksHeader.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/24/23.
//

import SwiftUI

struct PastTasksHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let dateString: String
    
    @ObservedObject var isScrolledToTop = ObservableBool(false)

    var body: some View {
        let color = colorForDateString(dateString)

        HStack {
            Text(dateString)
                .font(.system(.footnote, weight: .medium))
                .textCase(.uppercase)
                .padding(.vertical, 2).padding(.horizontal, 8)
                .foregroundColor(color)
                .brightness(colorScheme == .dark ? 0.2 : -0.3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .brightness(colorScheme == .dark ? -0.3 : 0.15)
                        .saturation(colorScheme == .dark ? 0.3 : 0.6)
                )
                .opacity(colorScheme == .dark ? 1.0 : 0.8)
            Spacer()
        }
        .opacity(isScrolledToTop.value ? 0.6 : 1.0)
        .animation(.default, value: isScrolledToTop.value)
    }

    private func colorForDateString(_ dateString: String) -> Color {
        let date = TaskNote.sectionFormatter.date(from: dateString)
        var progress: Double?
        let progressPerDay = 0.04

        if let date {
            let timeSinceDate = Date.now.timeIntervalSince(date)
            let daysSinceDate = (timeSinceDate / 60 / 60 / 24).rounded()
            progress = progressPerDay * (daysSinceDate - 1)
            progress = progress?.clamped(to: 0...1)
        }
        // NamedColor incorrectly switches from light to dark mode
        // so colors are manual here instead of Color("BarRest")
        let fromColor = colorScheme == .dark ? Color(hex: 0xD2544F) : Color(hex: 0xFC7974)
        let toColor = colorScheme == .dark ? Color(hex: 0x22B159) : Color(hex: 0x31E377)

        return Color.interpolate(from: fromColor, to: toColor, progress: progress ?? 1.0)
    }
}
