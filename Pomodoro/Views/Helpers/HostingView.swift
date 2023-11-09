//
//  HostingView.swift
//  Pomodoro
//
//  Created by Porter Glines on 3/12/23.
//

import SwiftUI

extension View {
    @ViewBuilder func reverseStatusBarColor() -> some View {
        // iOS 17 automatically determines statusbar color based on background
        if #available(iOS 17, *) {
            self
        } else {
            ModifiedContent(content: self, modifier: ReverseStatusBarColorModifier())
        }
    }
}

struct ReverseStatusBarColorModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        HostingView(colorScheme: colorScheme) {
            content
        }
        .ignoresSafeArea()
    }
}

struct HostingView<Content: View>: UIViewControllerRepresentable {
    var colorScheme: ColorScheme
    var content: Content

    init(colorScheme: ColorScheme, @ViewBuilder content: () -> Content) {
        self.colorScheme = colorScheme
        self.content = content()
    }

    func makeUIViewController(context: Context) -> HostingViewController<Content> {
        return HostingViewController(colorScheme: self.colorScheme, content: self.content)
    }

    func updateUIViewController(_ uiViewController: HostingViewController<Content>, context: Context) {
        uiViewController.colorScheme = context.environment.colorScheme
    }
}

class HostingViewController<Content: View>: UIViewController {
    var colorScheme: ColorScheme
    var content: UIHostingController<Content>

    init(colorScheme: ColorScheme, content: Content) {
        self.colorScheme = colorScheme
        self.content = UIHostingController(rootView: content)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        colorScheme == .dark ? .darkContent : .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(content)
        view.addSubview(content.view)

        content.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.view.topAnchor.constraint(equalTo: view.topAnchor),
            content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
