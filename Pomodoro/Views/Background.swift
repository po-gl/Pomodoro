//
//  Background.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/19/23.
//

import SwiftUI

struct Background: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
            GeometryReader { geometry in
                VStack (spacing: 0) {
                    Top(at: context.date)
                        .frame(height: geometry.size.height / 2.5 + (colorScheme == .dark ? 15 : -15))
                    PickGradient().zIndex(1)
                    Bottom(at: context.date)
                    
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: pomoTimer.getStatus(atDate: context.date))
            }
        }
    }
    
    @ViewBuilder
    private func Top(at date: Date) -> some View {
        Rectangle()
            .foregroundColor(getTopColor(at: date))
            .overlay(
                Rectangle()
                    .fill(LinearGradient(colors: [colorScheme == .dark ? .white : .clear, .clear], startPoint: .top, endPoint: .bottom))
                    .blendMode(.softLight)
            )
    }
    
    @ViewBuilder
    private func Bottom(at date: Date) -> some View {
        Rectangle()
            .foregroundColor(getBottomColor(at: date))
            .overlay(
                Rectangle()
                    .fill(LinearGradient(colors: [colorScheme == .light ? .white : .clear, .clear], startPoint: .top, endPoint: .bottom))
                    .opacity(0.6)
                    .blendMode(.softLight)
            )
    }
    
    @ViewBuilder
    private func PickGradient() -> some View {
        Image("PickGradient")
            .frame(width: 0, height: 0)
            .offset(y: 20)
            .rotationEffect(.degrees(colorScheme == .dark ? 180 : 0))
    }
    
    
    private func getBottomColor(at date: Date) -> Color {
        if colorScheme == .dark {
            return .black
        } else if pomoTimer.isPaused {
            return Color("BackgroundStopped")
        }
        
        switch pomoTimer.getStatus(atDate: date) {
        case .work:
            return Color("BackgroundWork")
        case .rest:
            return Color("BackgroundRest")
        case .longBreak:
            return Color("BackgroundLongBreak")
        case .end:
            return Color("BackgroundLongBreak")
        }
    }
    
    private func getTopColor(at date: Date) -> Color {
        if colorScheme == .light {
            return .black
        }
        
        switch pomoTimer.getStatus(atDate: date) {
        case .work:
            return Color("BarWork")
        case .rest:
            return Color("BarRest")
        case .longBreak:
            return Color("BarLongBreak")
        case .end:
            return Color("BarLongBreak")
        }
    }
}
