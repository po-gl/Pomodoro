//
//  UIFont+rounded.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/21/24.
//

import UIKit

extension UIFont {
    func asBoldRounded() -> UIFont {
        UIFont(
            descriptor:
                self.fontDescriptor
                .withDesign(.rounded)?
                .withSymbolicTraits(.traitBold) ?? self.fontDescriptor,
            size: self.pointSize
        )
    }
}
