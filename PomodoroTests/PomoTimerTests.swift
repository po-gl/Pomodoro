//
//  PomoTimer.swift
//  PomodoroTests
//
//  Created by Porter Glines on 10/26/22.
//

import XCTest

final class PomoTimerTests: XCTestCase {
    
    private var pomoTimer = PomoTimer(pomos: 0, longBreak: 0.0, perform: { _ in return })
    private var actionsPerformed = 0
    private var status: PomoStatus?

    override func setUpWithError() throws {
        actionsPerformed = 0
        status = nil
        pomoTimer = PomoTimer(pomos: 2, longBreak: PomoTimer.defaultBreakTime, perform: { status in
            self.status = status
            self.actionsPerformed += 1
        }, timeProvider: MockTimer.self)
    }

    override func tearDownWithError() throws {
    }
    
    func testPomoTimer_defaults() throws {
        XCTAssertEqual(PomoTimer.defaultWorkTime, 25.0 * 60.0)
        XCTAssertEqual(PomoTimer.defaultRestTime, 5.0 * 60.0)
        XCTAssertEqual(PomoTimer.defaultBreakTime, 30.0 * 60.0)
    }
    

    func testPomoTimerInit() throws {
        let now = Date()
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.work)
        XCTAssertEqual(pomoTimer.getStatusString(atDate: now), PomoStatus.work.rawValue)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), PomoTimer.defaultWorkTime)
        XCTAssertEqual(pomoTimer.isPaused, false)
    }
    
    func testPomoTimer_rangeOfStatusesAndTimeRemainings() throws {
        var now = Date()
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.work)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), PomoTimer.defaultWorkTime)
        
        now.addTimeInterval(PomoTimer.defaultWorkTime)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.work)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 0.0)
        
        now.addTimeInterval(1.0)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.rest)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), PomoTimer.defaultRestTime)
        
        now.addTimeInterval(PomoTimer.defaultRestTime)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.rest)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 0.0)
        
        now.addTimeInterval(1.0)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.work)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), PomoTimer.defaultWorkTime)
        
        now.addTimeInterval(PomoTimer.defaultWorkTime)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.work)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 0.0)
        
        now.addTimeInterval(1.0)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.rest)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), PomoTimer.defaultRestTime)
        
        now.addTimeInterval(PomoTimer.defaultRestTime)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.rest)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 0.0)
        
        now.addTimeInterval(1.0)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.longBreak)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), PomoTimer.defaultBreakTime)
        
        now.addTimeInterval(PomoTimer.defaultBreakTime - 1.0)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.longBreak)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 1.0)
        
        now.addTimeInterval(1.0)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.end)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 0.0)
    }
    
    
    func testPomoTimer_getStatusPastEnd() throws {
        var now = Date().addingTimeInterval(PomoTimer.defaultWorkTime * 2.0 + PomoTimer.defaultRestTime * 2.0 + Double(pomoTimer.pomoCount)*2.0 + PomoTimer.defaultBreakTime)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.end)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 0.0)
        now.addTimeInterval(1.0)
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), PomoStatus.end)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), 0.0)
    }
    
    func testPomoTimer_pausing() throws {
        let now = Date().addingTimeInterval(PomoTimer.defaultWorkTime + 1.0)
        pomoTimer.pause()
        XCTAssertEqual(pomoTimer.getStatus(atDate: now), .work)
        XCTAssertEqual(pomoTimer.timeRemaining(atDate: now), PomoTimer.defaultWorkTime)
    }
    
    func testPomoTimer_actionsPerformed() throws {
        var time = PomoTimer.defaultWorkTime + 1.0
        
        passTime(seconds: Int(time))
        XCTAssertEqual(actionsPerformed, 1)
        XCTAssertEqual(status, .rest)
        
        time += PomoTimer.defaultRestTime + 1.0
        passTime(seconds: Int(time))
        XCTAssertEqual(actionsPerformed, 2)
        XCTAssertEqual(status, .work)
    }
    
    func testPomoCount_increment() throws {
        pomoTimer.incrementPomos()
        XCTAssertEqual(pomoTimer.pomoCount, 3)
        XCTAssertEqual(pomoTimer.order.count, 7)
        XCTAssertEqual(pomoTimer.isPaused, true)
    }
    
    func testPomoCount_decrement() throws {
        pomoTimer.decrementPomos()
        XCTAssertEqual(pomoTimer.pomoCount, 1)
        XCTAssertEqual(pomoTimer.order.count, 3)
        XCTAssertEqual(pomoTimer.isPaused, true)
    }
    
    func testPomoTimer_reset() throws {
        pomoTimer.reset()
        XCTAssertEqual(pomoTimer.isPaused, true)
    }
    
    func testPomoTimer_saveAndRestore() throws {
        pomoTimer.saveToUserDefaults()
        pomoTimer.restoreFromUserDefaults()
        
        XCTAssertEqual(pomoTimer.pomoCount, 2)
        XCTAssertEqual(pomoTimer.order.count, 5)
    }
    
    
    private func passTime(seconds: Int) {
        for _ in 0..<seconds {
            MockTimer.currentTimer.fire()
        }
    }
}
