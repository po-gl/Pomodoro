//
//  PomoTimeTests.swift
//  PomodoroTests
//
//  Created by Porter Glines on 10/26/22.
//

import XCTest

final class PomoTimeTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testPomoTimeInit() throws {
        let pomoTime = PomoTime(1.0, .work)

        XCTAssertEqual(pomoTime.timeInterval, 1.0)
        XCTAssertEqual(pomoTime.status, PomoStatus.work)
        XCTAssertEqual(pomoTime.statusString, PomoStatus.work.rawValue)
    }

    func testPomoTimeEncodeAndDecode() throws {
        let pomoTime = PomoTime(70.0 * 60.0, .longBreak)

        let encoded = try PropertyListEncoder().encode(pomoTime)
        let decoded = try PropertyListDecoder().decode(PomoTime.self, from: encoded)

        XCTAssertEqual(decoded.timeInterval, 70.0 * 60.0)
        XCTAssertEqual(decoded.status, PomoStatus.longBreak)
        XCTAssertEqual(decoded.statusString, PomoStatus.longBreak.rawValue)
    }
}
