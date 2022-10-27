//
//  TimerTests.swift
//  PomodoroTests
//
//  Created by Porter Glines on 6/17/22.
//

import XCTest

final class SequenceTimerTests: XCTestCase {
    
    var sequenceTimer = SequenceTimer([], perform: { _ in return }, timerProvider: MockTimer.self)
    var actionsPerformed = 0

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let intervals = [2.0, 3.0]
        actionsPerformed = 0
        sequenceTimer = SequenceTimer(intervals, perform: { i in
            self.actionsPerformed += 1
        }, timerProvider: MockTimer.self)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
    
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    
    func passTime(seconds: Int) {
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
