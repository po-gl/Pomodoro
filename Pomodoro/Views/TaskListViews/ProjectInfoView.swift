//
//  ProjectInfoView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/15/23.
//

import SwiftUI

struct ProjectInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var project: Project
    @State var editText = ""
    @State var editColor: String = ""
    @FocusState var focus
    
    @State var color: Color = Color("BarRest")
    
    var colorNames: [String] = ["BarRest", "BarWork", "BarLongBreak", "End", "AccentColor"]
    
    var collapsedBackgroundBrightness: Double { colorScheme == .dark ? -0.09 : 0.1 }
    var collapsedBackgroundSaturation: Double { colorScheme == .dark ? 0.8 : 1.1 }
    var backgroundBrightness: Double { colorScheme == .dark ? -0.7 : 0.33 }
    var backgroundSaturation: Double { colorScheme == .dark ? 0.8 : 0.33 }
    
    var body: some View {
        ZStack (alignment: .topLeading) {
            ScrollView {
                VStack (spacing: 15) {
                    GroupBox {
                        VStack (spacing: 15) {
                            SelectedColorView()
                            GroupBox {
                                ProjectNameView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    .padding(.horizontal)
                    
                    GroupBox {
                        Grid {
                            GridRow {
                                ForEach(colorNames, id: \.self) { name in
                                    ColorSelect(name: name)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            }
            Header()
        }
        .onAppear {
            editText = project.name ?? ""
            editColor = project.color ?? ""
            color = Color(project.color ?? "BarRest")
        }
        .onChange(of: editColor) { _ in
            color = Color(editColor)
        }
        
        .focused($focus)
        .onChange(of: focus) { _ in
            guard !focus else { return }
            saveEdits()
        }
    }
    
    @ViewBuilder
    private func SelectedColorView() -> some View {
        let size: Double = 80
        HStack {
            GradientCircle(color)
                .frame(width: size, height: size)
                .brightness(collapsedBackgroundBrightness)
                .saturation(collapsedBackgroundSaturation)
            
            GradientCircle(color)
                .frame(width: size, height: size)
                .brightness(backgroundBrightness)
                .saturation(backgroundSaturation)
                .overlay(
                    GradientBorder(color)
                        .brightness(collapsedBackgroundBrightness)
                        .saturation(collapsedBackgroundSaturation)
                )
        }
    }
    
    @ViewBuilder
    private func ProjectNameView() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .multilineTextAlignment(.center)
            .font(.title3)
            .onSubmitWithVerticalText(with: $editText) {
                saveEdits()
            }
            .foregroundColor(color)
    }
    
    @ViewBuilder
    private func ColorSelect(name: String) -> some View {
        let size: Double = 40
        Button(action: { editColor = name }) {
            GradientCircle(Color(name))
                .frame(width: size, height: size)
        }
    }
    
    @ViewBuilder
    private func GradientCircle(_ color: Color) -> some View {
        Circle()
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
    }
    
    @ViewBuilder
    private func GradientBorder(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color.gradient, lineWidth: 2)
            .rotationEffect(.degrees(180))
    }
    
    
    
    @ViewBuilder
    private func Header() -> some View {
        VStack {
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                    }
                    Spacer()
                    
                    Button(action: {
                        saveEdits()
                        dismiss()
                    }) {
                        Text("Done").bold()
                    }
                }
                .padding()
                Text("Project Info")
            }
            .frame(height: 50)
            .background(.thinMaterial)
            Spacer()
        }
    }
    
    private func saveEdits() {
        if !editColor.isEmpty {
            ProjectsData.setColor(editColor, for: project, context: viewContext)
        }
        ProjectsData.editName(editText, for: project, context: viewContext)
    }
}