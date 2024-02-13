//
//  iOSWidgetBundle.swift
//  iOSWidget
//
//  Created by Porter Glines on 1/23/23.
//

import WidgetKit
import SwiftUI

@main
struct iOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        iOSWidgetLiveActivity()
        ProgressWidget()
        StatusWidget()
        StandByWidget()
        iOSWidget()
    }
}
