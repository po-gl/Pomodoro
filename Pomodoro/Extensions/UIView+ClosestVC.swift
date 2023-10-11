//
//  UIView+ClosestVC.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation
import UIKit

extension UIView {
    func closestVC() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}
