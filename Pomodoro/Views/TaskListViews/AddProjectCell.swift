//
//  AddProjectCell.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/13/23.
//

import SwiftUI
import Combine

struct AddProjectCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var projectName = ""
    @State var progress = 0.0
    
    var scrollProxy: ScrollViewProxy
    let id = ObjectIdentifier(Int.self)
    
    @FocusState var focus
    
    var body: some View {
        HStack (alignment: .top, spacing: 15) {
            if projectName.isEmpty {
                Plus().padding(.top, 3)
            }
            
            TextField("", text: $projectName, axis: .vertical)
                .font(.title3)
                .focused($focus)
                .onSubmitWithVerticalText(with: $projectName) {
                    addProject()
                }
                .onChange(of: focus) { _ in
                    if focus {
                        basicHaptic()
                    } else {
                        addProject()
                    }
                }
            
                .onChange(of: projectName) { taskText in
                    if taskText.isEmpty {
                        progress = 0.0
                    }
                }
            
                .id(id)
                .scrollToOnFocus(proxy: scrollProxy, focus: focus, id: id)
            
            if !projectName.isEmpty {
                ProgressCheck().padding(.top, 3)
            }
        }
    }
    
    private func addProject() {
        guard !projectName.isEmpty else { return }
        withAnimation {
            ProjectsData.addProject(projectName, progress: progress, order: Int16.max, context: viewContext)
        }
        projectName = ""
    }
    
    
    @ViewBuilder
    private func Plus() -> some View {
        let width: Double = 16
        Text("+")
            .opacity(0.5)
            .frame(width: width, height: width)
    }
    
    @ViewBuilder
    private func ProgressCheck() -> some View {
        let width: Double = 20
        ZStack {
            Circle().stroke(style: StrokeStyle(lineWidth: 1))
                .opacity(progress == 1.0 ? 1.0 : 0.5)
            ZStack {
                Circle()
                    .opacity(progress > 0.0 ? 1.0 : 0.0)
                    .mask {
                        VStack (spacing: 0) {
                            Rectangle().fill(.clear).frame(height: width * (1-progress))
                            Rectangle().frame(height: width * progress)
                        }
                    }
            }.frame(width: width/1.5)
        }
        .foregroundColor(progress > 0.0 ? Color("AccentColor") : .primary)
        .frame(width: width)
        .onTapGesture {
            let newValue = progress + 0.5 > 1.0 ? 0.0 : progress + 0.5
            
            
            withAnimation {
                progress = newValue
            }
            
            if newValue == 1.0 {
                resetHaptic()
            } else {
                basicHaptic()
            }
        }
    }
}

