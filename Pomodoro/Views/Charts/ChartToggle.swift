//
//  ChartToggle.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/8/24.
//

import SwiftUI

struct ChartToggle: View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var isOn: Bool

    let label: String

    var showData: Bool = true
    var value: Double = 0.0
    var unit: String = ""

    let color: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(String(format: "%.1f", value))
                    .fontWeight(.medium)
                Text(unit)
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .light ? .secondary : isOn ? .primary : .secondary)
            }
            .opacity(showData ? 1.0 : 0.0)
        }
        .font(.callout)
        .padding()
        .background(isOn ? color : Color.background)
        .foregroundStyle(colorScheme == .light ? .black : isOn ? .black : .white)
        .brightness(colorScheme == .dark ? 0.07 : 0.0)
        .brightness(isOn ? 0.0 : colorScheme == .dark ? 0.07 : -0.1)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            basicHaptic()
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn.toggle()
                }
            }
        }
    }
}
