//
//  WorkShift.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 18/6/25.
//

import Foundation

struct WorkShift: Codable, Identifiable, Equatable {
    var id: String
    let type: WorkShiftType
    let startTime: Date
    let endTime: Date
    let hoursWorked: Double
    let dayOfWeek: DayOfWeek
    
    var dictionary: [String: Any] {
        [
            "type": type.rawValue,
            "startTime": startTime,
            "endTime": endTime,
            "hoursWorked": hoursWorked,
            "dayOfWeek": dayOfWeek.rawValue
        ]
    }
    
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
}
