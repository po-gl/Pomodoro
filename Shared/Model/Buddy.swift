//
//  Buddy.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/2/24.
//

import SwiftUI

enum Buddy: String, Codable, CaseIterable {
    case tomato
    case blueberry
    case banana
}

class BuddySelection: ObservableObject {
    static var shared = BuddySelection()

    @Published var selection: [Buddy: Bool] {
        didSet {
            saveSelection()
        }
    }

    var selectedBuddies: [Buddy] {
        selection.filter { $0.value }.map { $0.key }
    }

    init() {
        if let savedSelection = UserDefaults.pomo?.object(forKey: "buddySelection") as? Data,
           let decodedSelection = try? PropertyListDecoder().decode([Buddy: Bool].self, from: savedSelection) {
            self.selection = decodedSelection
        } else {
            self.selection = Dictionary(uniqueKeysWithValues: Buddy.allCases.map { ($0, true)})
        }
    }

    func toggle(_ buddy: Buddy) {
        selection[buddy]?.toggle()
    }

    func resetToDefault() {
        selection = Dictionary(uniqueKeysWithValues: Buddy.allCases.map { ($0, true)})
    }

    private func saveSelection() {
        if let encodedSelection = try? PropertyListEncoder().encode(selection) {
            UserDefaults.pomo?.set(encodedSelection, forKey: "buddySelection")
        }
    }
}
