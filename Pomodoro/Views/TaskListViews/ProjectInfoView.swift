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
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 15) {
                    GroupBox {
                        VStack(spacing: 15) {
                            selectedColorView()
                            GroupBox {
                                projectNameView()
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
                                    colorSelect(name: name)
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
            header()
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
    private func selectedColorView() -> some View {
        let size: Double = 80
        HStack {
            gradientCircle(color)
                .frame(width: size, height: size)
                .brightness(collapsedBackgroundBrightness)
                .saturation(collapsedBackgroundSaturation)

            gradientCircle(color)
                .frame(width: size, height: size)
                .brightness(backgroundBrightness)
                .saturation(backgroundSaturation)
                .overlay(
                    gradientBorder(color)
                        .brightness(collapsedBackgroundBrightness)
                        .saturation(collapsedBackgroundSaturation)
                )
        }
    }

    @ViewBuilder
    private func projectNameView() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .multilineTextAlignment(.center)
            .font(.title3)
            .onSubmitWithVerticalText(with: $editText) {
                saveEdits()
            }
            .foregroundColor(color)
    }

    @ViewBuilder
    private func colorSelect(name: String) -> some View {
        let size: Double = 40
        Button(action: { editColor = name }) {
            gradientCircle(Color(name))
                .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    private func gradientCircle(_ color: Color) -> some View {
        Circle()
            .fill(color.gradient)
            .rotationEffect(.degrees(180))
    }

    @ViewBuilder
    private func gradientBorder(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color.gradient, lineWidth: 2)
            .rotationEffect(.degrees(180))
    }

    @ViewBuilder
    private func header() -> some View {
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
        ProjectsData.edit(editText, for: project, context: viewContext)
    }
}
