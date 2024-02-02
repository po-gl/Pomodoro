//
//  IntroView.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/1/24.
//

import SwiftUI

struct IntroView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("A Tool for the\nPomodoro Technique  🍅")
                            .font(.title)
                            .fontDesign(.rounded)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    Text(try! AttributedString(markdown: "Work for ___25 minutes___, rest for ___5 minutes___, repeat 3 more times, and then take a longer break."))
                        .font(.callout)
                        .fontWeight(.regular)
                        .padding(.leading, 30)
                        .padding(.trailing, 20)
                }
                .padding(.top, 80)
                
                Divider()
                    .padding(.top, 25)
                    .padding(.bottom, 10)

                pomodoroBarDiagram(geometry)

                Spacer()
            }
            .padding(.horizontal)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }

    @ViewBuilder
    var pomodoroGoals: some View {
        HStack {
            Text("🎉  Goals of Pomodoro:")
                .font(.headline)
            Spacer()
        }
        .padding(.bottom, 20)
        BulletedList(textList: [
            "Improving your _focus_ and _concentration_",
            "Increasing your _awareness of decisions_ made throughout the day",
            "Refining the accuracy of time _estimations_ for tasks"
        ], spacing: 20)
        .frame(maxWidth: 400)
        .padding(.horizontal)
        .font(.body)
        .fontWeight(.regular)
    }

    @ViewBuilder
    func pomodoroBarDiagram(_ geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                section(for: .work)
                    .frame(width: geometry.size.width * (18 / 60))
                section(for: .rest)
                    .frame(width: geometry.size.width * (5 / 60))
//                VStack {
//                    Text(".").font(.body).fixedSize().opacity(0.0)
//                    minifiedPomodoro
//                    Text(".").font(.body).fixedSize().opacity(0.0)
//                }
                VStack {
                    Text(".").font(.body).fixedSize().opacity(0.0)
                    dots
                    Text(".").font(.body).fixedSize().opacity(0.0)
                }
                section(for: .longBreak)
                    .frame(width: geometry.size.width * (21 / 60))
            }
            .frame(height: 100)
            VStack(spacing: 2) {
                brackets(geometry)
                    .foregroundStyle(.secondary)
                Text("1 Pomodoro")
                    .font(.callout)
                    .fontDesign(.rounded)
                    .fontWeight(.regular)
            }
            .opacity(0.6)
        }
    }
    
    @ViewBuilder
    func section(for status: PomoStatus) -> some View {
        VStack {
            Text(String(format: "%.0f min", status.defaultTime / 60))
                .font(.body)
                .fontDesign(.rounded)
                .fontWeight(.medium)
                .fixedSize()
            bar(for: status)
            Text(status.rawValue)
                .font(.body)
                .fontDesign(.rounded)
                .fontWeight(.medium)
                .fixedSize()
        }
    }

    @ViewBuilder var minifiedPomodoro: some View {
        HStack(spacing: 2) {
            bar(for: .work)
            bar(for: .rest)
        }
    }

    @ViewBuilder
    func bar(for status: PomoStatus, outline: CGFloat = 2) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.black)
            .frame(height: 12)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ProgressBar.getGradient(for: status))
                    .padding(outline)
            }
    }

    @ViewBuilder var bullet: some View {
        let size = 5.0
        Circle()
            .fill(.secondary)
            .frame(width: size, height: size)
    }

    @ViewBuilder var dots: some View {
        let size = 4.0
        HStack(spacing: 2) {
            Group {
                Circle()
                Circle()
                Circle()
            }
            .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    func brackets(_ geometry: GeometryProxy) -> some View {
        let thickness = 2.0
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                Rectangle().frame(width: thickness, height: 10)
                Rectangle().frame(width: geometry.size.width * ((18 + 5) / 60) + 10, height: thickness)
                Rectangle().frame(width: thickness, height: 10)
            }
            Rectangle().frame(width: thickness, height: 20)
        }
    }
}

#Preview("Base View") {
    IntroView()
}

#Preview("From Sheet") {
    Text("Base")
        .sheet(isPresented: Binding(get: { true }, set: { _ in } )) {
            ZStack {
                OnBoardViewBackground(color: .barWork)
                    .ignoresSafeArea()
                IntroView()
                    .presentationDragIndicator(.visible)
                    .padding(.top, 60)
            }
        }
}
