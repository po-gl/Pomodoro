//
//  BuddyView.swift
//  Pomodoro
//
//  Created by Porter Glines on 11/1/22.
//

import SwiftUI

struct BuddyView: View {
    @ObservedObject var pomoTimer: PomoTimer
    
    var body: some View {
        if pomoTimer.isPaused {
            SitAnimation()
        } else {
            WalkAnimation()
        }
    }
}

struct BuddyView_Previews: PreviewProvider {
    static let pomoTimer = PomoTimer()
    static var previews: some View {
        BuddyView(pomoTimer: pomoTimer)
    }
}
