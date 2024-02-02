//
//  BulletedList.swift
//  Pomodoro
//
//  Created by Porter Glines on 2/1/24.
//

import SwiftUI

struct BulletedList: View {
    var textList: [String]
    var withIcons: [AnyView]?
    var spacing: CGFloat = 10.0

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(zip(textList.indices, textList)), id: \.0) { i, text in
                HStack(alignment: .firstTextBaseline, spacing: 15) {
                    if let withIcons, i < withIcons.count {
                        withIcons[i]
                            .padding(.trailing, 8)
                    } else {
                        bullet
                            .offset(y: -3)
                    }
                    Text(try! AttributedString(markdown: text))
                }
            }
        }
    }

    var bullet: some View {
        Circle()
            .fill(.secondary)
            .frame(width: 5, height: 5)
    }
}

#Preview {
    BulletedList(textList: [
        "Lorem **ipsum** dolor sit amet, consectetur adipiscing elit. Nunc placerat ullamcorper tempus. Nullam id tortor vitae ligula porttitor dignissim.",
        "Phasellus non _vestibulum_ nibh, id facilisis nibh.",
        "Mauris condimentum, sem ac luctus pretium, ante lectus consectetur turpis, a sodales massa nunc non velit. ___Suspendisse___ luctus, lorem at accumsan ornare, quam neque dictum arcu, commodo semper dui sem vitae diam.",
    ])
    .padding()
}
