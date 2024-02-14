//
//  TimerTests.swift
//  PomodoroTests
//
//  Created by Porter Glines on 6/17/22.
//

import XCTest
@testable import Pomodoro

final class SequenceTimerTests: XCTestCase {

    var sequenceTimer = SequenceTimer([], perform: { _ in return }, timerProvider: MockTimer.self)
    var actionsPerformed = 0

    override func setUpWithError() throws {
        let intervals = [2.0, 3.0]
        actionsPerformed = 0
        sequenceTimer = SequenceTimer(intervals, perform: { _ in
            self.actionsPerformed += 1
        }, timerProvider: MockTimer.self)
        sequenceTimer.start()
    }

    override func tearDownWithError() throws {
    }

    func testSequenceTimerInitializer() throws {
        let now = Date()
        XCTAssertEqual(sequenceTimer.getIndex(atDate: now), 0)
        XCTAssertEqual(sequenceTimer.timeRemaining(atDate: now), 2.0)
    }

    func testInIntervalOne_AfterOneSecond() throws {
        let now = Date().addingTimeInterval(1.0)
        XCTAssertEqual(sequenceTimer.getIndex(atDate: now), 0)
        XCTAssertEqual(sequenceTimer.timeRemaining(atDate: now), 1.0)
    }

    func testInIntervalOne_AfterTwoSeconds() throws {
        let now = Date().addingTimeInterval(2.0)
        XCTAssertEqual(sequenceTimer.getIndex(atDate: now), 0)
        XCTAssertEqual(sequenceTimer.timeRemaining(atDate: now), 0.0)
    }

    func testInIntervalTwo() throws {
        let now = Date().addingTimeInterval(3.0)
        XCTAssertEqual(sequenceTimer.getIndex(atDate: now), 1)
        XCTAssertEqual(sequenceTimer.timeRemaining(atDate: now), 3.0)
    }

    func testInIntervalTwo_atEnd() throws {
        let now = Date().addingTimeInterval(6.0)
        XCTAssertEqual(sequenceTimer.getIndex(atDate: now), 1)
        XCTAssertEqual(sequenceTimer.timeRemaining(atDate: now), 0.0)
    }

    func testPastEnd() throws {
        let now = Date().addingTimeInterval(8.0)
        XCTAssertEqual(sequenceTimer.getIndex(atDate: now), 1)
        XCTAssertEqual(sequenceTimer.timeRemaining(atDate: now), 0.0)
    }

    func testPauseTimer() throws {
        sequenceTimer.pause()
        XCTAssertTrue(sequenceTimer.isPaused)
    }

    func testResetTimer() throws {
        passTime(seconds: 8)
        sequenceTimer.reset()
        passTime(seconds: 3)
        XCTAssertEqual(actionsPerformed, 3)
    }

    func testIsReset() throws {
        XCTAssertEqual(sequenceTimer.isReset, false)
        passTime(seconds: 1)
        sequenceTimer.reset()
        XCTAssertEqual(sequenceTimer.isReset, true)
        sequenceTimer.unpause()
        XCTAssertEqual(sequenceTimer.isReset, false)
    }

    func testSequenceTimerPerformance() throws {
        let sequenceOfIntervals: [TimeInterval] = Array(repeating: 10.0*60.0, count: 100)
        let sequenceTimer = SequenceTimer(sequenceOfIntervals, perform: { _ in return }, timerProvider: MockTimer.self)
        sequenceTimer.start()

        let index = 97.0
        let now = Date().addingTimeInterval((10.0 * 60.0)*index + 1.0*index)
        self.measure {
            XCTAssertEqual(sequenceTimer.getIndex(atDate: now), Int(index))
            XCTAssertEqual(sequenceTimer.timeRemaining(atDate: now), 10.0 * 60.0)
        }
    }

    private func passTime(seconds: Int) {
        for _ in 0..<seconds {
            MockTimer.currentTimer.fire()
        }
    }
}

class MockTimer: Timer {
    var block: ((Timer) -> Void)!

    static var currentTimer: MockTimer!
    static var timeRemaining: TimeInterval!

    override func fire() {
        if MockTimer.timeRemaining == 0.0 {
            block(self)
        } else {
            MockTimer.timeRemaining -= 1.0
        }
    }

    override func invalidate() {
    }

    override open class func scheduledTimer(withTimeInterval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let mockTimer = MockTimer()
        mockTimer.block = block
        self.currentTimer = mockTimer
        self.timeRemaining = withTimeInterval
        return mockTimer
    }
}
