//
//  TopButton.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/12/23.
//

import SwiftUI

struct TopButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var pomoTimer: PomoTimer
    
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                TaskListButton()
            }
            .padding(.top, 20)
            .padding(.trailing, 40)
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: pomoTimer.getStatus())
    }
    
    @ViewBuilder
    private func TaskListButton() -> some View {
        let backgroundColor = colorScheme == .dark ? .black : getColorForStatus(pomoTimer.getStatus())
        let foregroundColor = colorScheme == .dark ? getColorForStatus(pomoTimer.getStatus()) : .black
        
        NavigationLink(destination: {
            TaskList()
                .navigationTitle(dayFormatter.string(from: Date()))
                .navigationBarTitleDisplayMode(.inline)
        }) {
            Image(systemName: "checklist")
                .frame(width: 50, height: 32)
                .foregroundColor(foregroundColor)
                .background(RoundedRectangle(cornerRadius: 30).foregroundColor(backgroundColor).background(RoundedRectangle(cornerRadius: 30).offset(x: 2, y: 2).foregroundColor(backgroundColor).brightness(-0.3)))
        }
    }
    
    private func getColorForStatus(_ status: PomoStatus) -> Color {
        switch status {
        case .work:
            return Color("BarWork")
        case .rest:
            return Color("BarRest")
        case .longBreak:
            return Color("BarLongBreak")
        case .end:
            return .accentColor
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE M/d")
        return formatter
    }()
}

