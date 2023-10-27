//
//  WrappingHStack.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/26/23.
//

import SwiftUI

// From https://stackoverflow.com/a/65453108
struct WrappingHStack<Model, V>: View where Model: Identifiable, Model: Hashable, V: View {
    typealias ViewGenerator = (Model) -> V

    var models: [Model]
    var viewGenerator: ViewGenerator
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 5

    @State private var totalHeight = CGFloat.zero

    init(models: [Model], @ViewBuilder viewGenerator: @escaping ViewGenerator) {
        self.models = models
        self.viewGenerator = viewGenerator
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.models) { model in
                viewGenerator(model)
                    .padding(.horizontal, horizontalSpacing)
                    .padding(.vertical, verticalSpacing)
                    .alignmentGuide(.leading, computeValue: { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        if model == self.models.last! {
                            width = 0 // last item
                        } else {
                            width -= dimension.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if model == self.models.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}
