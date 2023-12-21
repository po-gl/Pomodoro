//
//  Errors.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/21/23.
//

import Foundation
import Combine

/// For user-facing error messages
struct PomoError {
    var title: String
    var advice: String
}

class Errors: ObservableObject {
    static var shared = Errors()

    @Published var coreDataError: NSError?
    static var coreDataPomoError = PomoError(title: "Error Saving Data", advice: "Check if your device has free space and that you are signed in to iCloud")
}

