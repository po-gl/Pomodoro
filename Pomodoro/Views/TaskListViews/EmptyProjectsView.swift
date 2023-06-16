//
//  EmptyProjectsView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/15/23.
//

import SwiftUI

struct EmptyProjectsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    var cellHeight: Double = 85
    var color: Color = Color("EmptyGray")
    
    var primaryBrightness: Double { colorScheme == .dark ? 0.5 : -0.5 }
    var primarySaturation: Double { colorScheme == .dark ? 1.8 : 1.2 }
    var secondaryBrightness: Double { colorScheme == .dark ? 0.2 : -0.3 }
    var secondarySaturation: Double { colorScheme == .dark ? 1.0 : 1.0 }
    
    var collapsedBackgroundBrightness: Double { colorScheme == .dark ? -0.09 : 0.0 }
    var collapsedBackgroundSaturation: Double { colorScheme == .dark ? 0.85 : 1.1 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.5 : 0.1 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }
    var backgroundOpacity: Double { colorScheme == .dark ? 0.6 : 0.5 }
    
    
    var body: some View {
        Card {
            Text("Add a Project")
                .foregroundColor(color)
                .brightness(primaryBrightness)
                .saturation(primarySaturation)
        }
        .onTapGesture {
            ProjectsData.addProject("", context: viewContext)
        }
    }
    
    @ViewBuilder
    private func Card(@ViewBuilder content: @escaping () -> some View) -> some View {
        HStack (alignment: .top) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: cellHeight)
        .background(
            GradientRectangle()
                .brightness(collapsedBackgroundBrightness)
                .saturation(collapsedBackgroundSaturation)
        )
    }
    
    @ViewBuilder
    private func GradientRectangle() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
    }
}

struct EmptyProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyProjectsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding(.horizontal)
    }
}
