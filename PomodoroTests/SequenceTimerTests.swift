//
//  TimerTests.swift
//  PomodoroTests
//
//  Created by Porter Glines on 6/17/22.
//

import XCTest

final class SequenceTimerTests: XCTestCase {
    
    var sequenceTimer = SequenceTimer(sequenceOfIntervals: [], timerProvider: MockTimer.self)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let intervals = [2.0, 3.0]
        sequenceTimer = SequenceTimer(sequenceOfIntervals: intervals, timerProvider: MockTimer.self)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sequenceTimer.end()
    }

    func testSequenceTimerInitializer() throws {
        XCTAssertEqual(sequenceTimer.currentIndex, 0)
        XCTAssertEqual(sequenceTimer.timeRemaining, 2.0)
    }
    
    func testInIntervalOne_AfterOneSecond() throws {
        passTime(seconds: 1)
        XCTAssertEqual(sequenceTimer.currentIndex, 0)
        XCTAssertEqual(sequenceTimer.timeRemaining, 1.0)
    }
    
    func testInIntervalOne_AfterTwoSeconds() throws {
        passTime(seconds: 2)
        XCTAssertEqual(sequenceTimer.currentIndex, 0)
        XCTAssertEqual(sequenceTimer.timeRemaining, 0.0)
    }
    
    func testInIntervalTwo() throws {
        passTime(seconds: 3)
        XCTAssertEqual(sequenceTimer.currentIndex, 1)
        XCTAssertEqual(sequenceTimer.timeRemaining, 3.0)
    }
    
    func testInIntervalTwo_atEnd() throws {
        passTime(seconds: 6)
        XCTAssertEqual(sequenceTimer.currentIndex, 1)
        XCTAssertEqual(sequenceTimer.timeRemaining, 0.0)
    }
    
    func testRepeatingTimer() throws {
        passTime(seconds: 8)
        XCTAssertEqual(sequenceTimer.currentIndex, 0)
        XCTAssertEqual(sequenceTimer.timeRemaining, 1.0)
    }
    
    
    func testPauseTimer() throws {
        sequenceTimer.pause()
        XCTAssertTrue(sequenceTimer.isPaused)
    }
    
    func testResetTimer() throws {
        passTime(seconds: 5)
        sequenceTimer.reset()
        passTime(seconds: 1)
        XCTAssertEqual(sequenceTimer.currentIndex, 0)
        XCTAssertEqual(sequenceTimer.timeRemaining, 2.0)
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
    
    override func fire() {
        block(self)
    }
    
    override func invalidate() {
    }
    
    override open class func scheduledTimer(withTimeInterval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let mockTimer = MockTimer()
        mockTimer.block = block
        self.currentTimer = mockTimer
        return mockTimer
    }
}
