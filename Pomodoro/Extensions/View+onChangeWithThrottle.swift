//
//  View+onChangeWithThrottle.swift
//  Pomodoro
//
//  Created by Porter Glines on 1/22/24.
//

import SwiftUI
import Combine

extension View {
    func onChangeWithThrottle<E: Equatable>(of target: E,
                                            for interval: RunLoop.SchedulerTimeType.Stride,
                                            _ action: @escaping (E) -> Void) -> some View {
        ModifiedContent(content: self, modifier: OnChangeWithThrottleModifier(target: target,
                                                                              interval: interval,
                                                                              action: action))
    }
}
struct OnChangeWithThrottleModifier<E: Equatable>: ViewModifier {
    var target: E
    var interval: RunLoop.SchedulerTimeType.Stride
    var action: (E) -> Void

    @State var subject = PassthroughSubject<E, Never>()
    @State var subscriber: AnyCancellable?

    func body(content: Content) -> some View {
        content
            .onChange(of: target) { [weak subject] newValue in
                subject?.send(newValue)
            }
            .onAppear {
                guard subscriber == nil else { return }
                subscriber = subject
                    .receive(on: RunLoop.main)
                    .throttle(for: interval, scheduler: RunLoop.main, latest: true)
                    .sink { newValue in
                        action(newValue)
                    }
            }
    }
}
