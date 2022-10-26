//
//  PomoTime.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/20/22.
//

import Foundation


enum PomoStatus: String, Codable {
    case work = "Work"
    case rest = "Rest"
    case longBreak = "Long Break"
    case end = "Finished"
}


class PomoTime: Codable {
    private var timeInterval: TimeInterval
    private var status: PomoStatus
    
    init(_ time: TimeInterval, _ status: PomoStatus) {
        self.timeInterval = time
        self.status = status
    }
    
    func getTime() -> TimeInterval {
        return timeInterval
    }
    
    func getStatus() -> PomoStatus {
        return status
    }
    
    func getStatusString() -> String {
        return getStatus().rawValue
    }
    
    enum CodingKeys: String, CodingKey {
        case timeInterval
        case status
    }
    
    required init (from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        timeInterval = try values.decode(TimeInterval.self, forKey: .timeInterval)
        status = try values.decode(PomoStatus.self, forKey: .status)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeInterval, forKey: .timeInterval)
        try container.encode(status, forKey: .status)
    }
}