//
//  AlwaysPopoverModifier.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation
import SwiftUI

struct AlwaysPopoverModifier<PopoverContent>: ViewModifier where PopoverContent: View {
    
    let isPresented: Binding<Bool>
    let contentBlock: () -> PopoverContent
    
    // Workaround for missing @StateObject in iOS 13.
    private struct Store {
        var anchorView = UIView()
    }
    @State private var store = Store()
    
    func body(content: Content) -> some View {
        if isPresented.wrappedValue {
            presentPopover()
        }
        
        return content
            .background(InternalAnchorView(uiView: store.anchorView))
            .foregroundColor(.blue)
    }
    
    private func presentPopover() {
        let contentController = PopoverContentViewController(rootView: contentBlock(), isPresented: isPresented)
        contentController.view.backgroundColor = .clear
        contentController.modalPresentationStyle = .popover
        
        
        let view = store.anchorView
        guard let popover = contentController.popoverPresentationController else { return }
        popover.sourceView = view
        popover.sourceRect = view.bounds
        popover.delegate = contentController
        
        guard let sourceVC = view.closestVC() else { return }
        if sourceVC.presentedViewController != nil {
//            presentedVC.dismiss(animated: true) {
//                sourceVC.present(contentController, animated: true)
//            }
            sourceVC.present(contentController, animated: true)
        } else {
            sourceVC.present(contentController, animated: true)
        }
    }
    
    private struct InternalAnchorView: UIViewRepresentable {
        typealias UIViewType = UIView
        let uiView: UIView
        
        func makeUIView(context: Self.Context) -> Self.UIViewType {
            uiView
        }
        
        func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) { }
    }
}
