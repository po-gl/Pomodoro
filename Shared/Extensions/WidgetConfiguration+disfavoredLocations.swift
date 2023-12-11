//
//  WidgetConfiguration+disfavoredLocations.swift
//  Pomodoro
//
//  Created by Porter Glines on 12/10/23.
//

import SwiftUI
import WidgetKit

enum WidgetDisfavoredLocation {
    case homeScreen
    case lockScreen
    case standBy
    case iPhoneWidgetsOnMac
}

extension WidgetConfiguration {
    
    /// This is necessary since WidgetConfiguration isn't type erased and makes platform conditionals difficult
    func backDeployedDisfavoredLocations(_ locations: [WidgetDisfavoredLocation], for families: [WidgetFamily]) -> some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return disfavoredLocations(
                locations.map { location in
                    switch location {
                    case .homeScreen:
                        return .homeScreen
                    case .lockScreen:
                        return .lockScreen
                    case .standBy:
                        return .standBy
                    case .iPhoneWidgetsOnMac:
                        return .iPhoneWidgetsOnMac
                    }
                },
                for: families
            )
        } else {
            return self
        }
    }
}
