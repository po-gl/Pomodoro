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
                ZStack {
                    Rectangle()
                        .foregroundColor(getBottomColor(at: context.date))
                        .overlay(Rectangle().foregroundStyle(LinearGradient(stops: [.init(color: .white, location: 0.0), .init(color: .clear, location: 1.0)], startPoint: .bottom, endPoint: .top)).opacity(0.6).blendMode(.softLight))
                        .ignoresSafeArea()
                    if colorScheme == .light {
                        Image("PickGradient")
                            .scaleEffect(1.1)
                            .offset(y: -50)
                    }
                    ZStack {
                        VStack {
                            Rectangle()
                                .foregroundColor(getTopColor(at: context.date))
                                .frame(height: colorScheme == .dark ? geometry.size.height / 2 + 100 : geometry.size.height / 2 - 100)
                                .overlay(Rectangle().foregroundStyle(LinearGradient(stops: [.init(color: .white, location: 0.0), .init(color: .clear, location: 1.0)], startPoint: .top, endPoint: .bottom)).blendMode(.softLight))
                                .ignoresSafeArea()
                            Spacer()
                        }
                        if colorScheme == .dark {
                            Image("PickGradient")
                                .rotationEffect(.degrees(180))
                                .scaleEffect(1.1)
                                .offset(y: -50)
                        }
                    }
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: pomoTimer.getStatus(atDate: context.date))
            }
        }
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
