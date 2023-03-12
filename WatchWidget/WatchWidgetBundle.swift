//
//  WatchWidgetBundle.swift
//  WatchWidgetExtension
//
//  Created by Porter Glines on 3/11/23.
//

import WidgetKit
import SwiftUI

@main
struct PomoWidgets: WidgetBundle {
    var body: some Widget {
        StatusWatchWidget()
        ProgressWatchWidget()
    }
}
