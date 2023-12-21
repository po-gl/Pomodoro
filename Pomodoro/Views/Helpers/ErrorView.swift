//
//  ErrorView.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/21/23.
//

import SwiftUI

struct ErrorView: View {
    var pomoError: PomoError
    var nsError: NSError
    var showImmediately = false

    @State var showAlert = false

    var body: some View {
        Text(Image(systemName: "exclamationmark.triangle.fill"))
            .foregroundStyle(.red)
            .onTapGesture {
                showAlert = true
            }
            .alert(pomoError.title, isPresented: $showAlert, actions: {
                Button("Dismiss") {
                    showAlert = false
                }
            }, message: {
                Text("\(pomoError.advice)\n\nError code: \(nsError.code)")
            })
            .onAppear {
                showAlert = showImmediately
            }
    }
}

#Preview {
    ErrorView(pomoError: Errors.coreDataPomoError,
              nsError: NSError(domain: "Pomo", code: 7))
}
