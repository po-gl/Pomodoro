//
//  ProjectItemCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct ProjectItemCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    
    var scrollProxy: ScrollViewProxy
    
    @State var editText = ""
    @FocusState var focus
    
    var body: some View {
        HStack (alignment: .top, spacing: 15) {
            MainTextField()
            ProgressCheck()
        }
        .onAppear {
            editText = project.name!
        }
        
        .onChange(of: focus) { _ in
            guard !focus else { return }
            deleteOrEditProject()
        }
        .scrollToOnFocus(proxy: scrollProxy, focus: focus, id: project.id)
        
        .doneButton(isPresented: focus)
    }
    
    @ViewBuilder
    private func MainTextField() -> some View {
        TextField("", text: $editText, axis: .vertical)
            .font(.title3)
            .focused($focus)
            .onSubmitWithVerticalText(with: $editText) {
                deleteOrEditProject()
            }
    }
    
    private func deleteOrEditProject() {
        if editText.isEmpty {
            withAnimation { ProjectsData.delete(project, context: viewContext) }
        } else {
            ProjectsData.editName(editText, for: project, context: viewContext)
        }
    }
    
    
    @ViewBuilder
    private func ProgressCheck() -> some View {
        let width: Double = 24
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
