//
//  Env.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/16/23.
//

import Foundation

struct Vars: Decodable {
    let serverURL: String
}

class Env {
    static let shared = Env()

    var vars: Vars?

    init() {
        if let path = Bundle.main.url(forResource: "Env", withExtension: "plist") {
            if let data = try? Data(contentsOf: path) {
                vars = try? PropertyListDecoder().decode(Vars.self, from: data)
            }
        }
    }
}
