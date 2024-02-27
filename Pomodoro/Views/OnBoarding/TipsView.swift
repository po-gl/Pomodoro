//
//  TipsView.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/1/24.
//

import SwiftUI

struct TipsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isSmallDevice) var isSmallDevice
    @Environment(\.dismiss) var dismiss

    var color: Color

    var body: some View {
        VStack {
            HStack {
                Text("Mindset Tips")
                    .font(.title)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.top, 60)
            .padding(.bottom, isSmallDevice ? 15 : 35)
            BulletedList(textList: [
                "Think of the app as a tool to help you improve your own self-discipline rather than an external overseer of your work",
                "Don’t make expectations for yourself going in, just work and observe how many Pomodoros it takes for you to complete tasks.",
                "Take it easy at first, but then start to challenge yourself to estimate time accurately and complete tasks quickly (without shortcuts)."
            ], spacing: isSmallDevice ? 25 : 35)
            .frame(maxWidth: 400)
            .font(.body)
            .fontWeight(.regular)
            .lineSpacing(4.0)
            
            Divider()
                .padding(.vertical, 15)
            
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Text("Get Started")
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .fontWeight(.medium)
                        .fontDesign(.monospaced)
                }
                .accessibilityIdentifier("getStartedButton")
                .buttonStyle(PopStyle(color: color))
                .frame(width: 170, height: 50)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview("Base View") {
    TipsView(color: .barLongBreak)
        .environment(\.isSmallDevice, false)
}

#Preview("From Sheet") {
    Text("Base")
        .sheet(isPresented: Binding(get: { true }, set: { _ in } )) {
            ZStack {
                OnBoardViewBackground(color: .barLongBreak)
                    .ignoresSafeArea()
                TipsView(color: .barLongBreak)
                    .presentationDragIndicator(.visible)
                    .padding(.top, 60)
            }
        }
        .environment(\.isSmallDevice, false)
}
