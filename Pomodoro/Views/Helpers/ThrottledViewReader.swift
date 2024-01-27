//
//  ThrottledViewReader.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/26/24.
//

import SwiftUI
import Combine

struct ThrottledViewReader: View {
    @Binding var binding: CGRect

    var interval: RunLoop.SchedulerTimeType.Stride

    @State var subject = PassthroughSubject<CGRect, Never>()

    var body: some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .global)
            guard rect != binding else { return .clear }
            subject.send(rect)
            return .clear
        }
        .onReceive(subject
            .receive(on: RunLoop.main)
            .throttle(for: interval, scheduler: RunLoop.main, latest: true)) { newValue in
                binding = newValue
            }
    }
}
