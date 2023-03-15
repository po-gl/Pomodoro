//
//  ProjectItemCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI

struct ProjectItemCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    
    @State var editText = ""
    @FocusState var focus
    
    var body: some View {
        HStack (alignment: .top, spacing: 15) {
            TextField("", text: $editText, axis: .vertical)
                .font(.title3)
                .focused($focus)
                .onSubmitWithVerticalText(with: $editText) {
                    ProjectsData.editName(editText, for: project, context: viewContext)
                }
                .onChange(of: focus) { _ in
                    guard !focus else { return }
                    ProjectsData.editName(editText, for: project, context: viewContext)
                }
            ProgressCheck().padding(.top, 3)
        }
        .onAppear {
            editText = project.name!
        }
    }
    
    
    @ViewBuilder
    private func ProgressCheck() -> some View {
        let width: Double = 20
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1))
                .opacity(project.progress == 1.0 ? 1.0 : 0.5)
            ZStack {
                Circle()
                    .opacity(project.progress > 0.0 ? 1.0 : 0.0)
                    .mask {
                        VStack (spacing: 0) {
                            Rectangle().fill(.clear).frame(height: width * (1-project.progress))
                            Rectangle().frame(height: width * project.progress)
                        }
                    }
            }.frame(width: width/1.5)
        }
        .foregroundColor(project.progress > 0.0 ? Color("AccentColor") : .primary)
        .frame(width: width)
        .onTapGesture {
            let newValue = project.progress + 0.5 > 1.0 ? 0.0 : project.progress + 0.5
            
            withAnimation {
                ProjectsData.setProgress(newValue, for: project, context: viewContext)
            }
            
            if newValue == 1.0 {
                resetHaptic()
            } else {
                basicHaptic()
            }
        }
    }
}
