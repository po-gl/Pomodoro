//
//  OnBoardView.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/30/24.
//

import SwiftUI

struct OnBoardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State var selectedTab = 0
    
    var bgColor: Color {
        switch selectedTab {
        case 0:
            return .barWork
        case 1:
            return .barRest
        case 2:
            return .barLongBreak
        default:
            return .black
        }
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                IntroView()
                    .tag(0)
                AppFeaturesView()
                    .tag(1)
                TipsView(color: bgColor)
                    .tag(2)
            } 
            .accessibilityIdentifier("onBoardingTabView")
            .tabViewStyle(.page)
            .background {
                OnBoardViewBackground(color: bgColor)
                    .ignoresSafeArea()
            }
            .animation(.easeInOut, value: bgColor)
            .toolbar {
                Button(action: {
                    dismiss()
                }) {
                    Text("Skip")
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                        .foregroundStyle(colorScheme == .dark ? .black : bgColor)
                        .brightness(colorScheme == .dark ? 0.0 : 0.7)
                        .saturation(colorScheme == .dark ? 1.0 : 0.8)
                }
                .accessibilityIdentifier("skipWelcomeButton")
            }
            .onAppear {
                changePageIndicators()
            }
            .onChange(of: colorScheme) {
                changePageIndicators()
            }
        }
#if targetEnvironment(macCatalyst)
        .ignoresSafeArea(edges: .horizontal)
#endif
    }
    
    func changePageIndicators() {
        let color: UIColor = colorScheme == .dark ? .white : .black
        UIPageControl.appearance().currentPageIndicatorTintColor = color
        UIPageControl.appearance().pageIndicatorTintColor = color.withAlphaComponent(0.2)
    }
}

#Preview("Base View") {
    OnBoardView()
}

#Preview("From Sheet") {
    Text("Base")
        .sheet(isPresented: Binding(get: { true }, set: { _ in})) {
            OnBoardView()
                .presentationDragIndicator(.visible)
        }
}
