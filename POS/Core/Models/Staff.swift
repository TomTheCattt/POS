import Foundation
import FirebaseFirestore

enum StaffPosition: String, Codable {
    case cashier = "Cashier"
    case waiter = "Waiter"
    
    var baseHourlyRate: Double {
        switch self {
        case .cashier: return 25000 // VND per hour
        case .waiter: return 22000 // VND per hour
        }
    }
    
    var displayName: String {
        switch self {
        case .cashier: return "Thu ngân"
        case .waiter: return "Phục vụ"
        }
    }
}

enum WorkShiftType: String, Codable {
    case fullTime = "Full-time"
    case partTime = "Part-time"
    
    var hoursPerShift: Double {
        switch self {
        case .fullTime: return 8.0
        case .partTime: return 4.0
        }
    }
    
    var displayName: String {
        switch self {
        case .fullTime: return "Toàn thời gian"
        case .partTime: return "Bán thời gian"
        }
    }
}

struct WorkShift: Codable, Identifiable {
    @DocumentID var id: String?
    let type: WorkShiftType
    let startTime: Date
    let endTime: Date
    let hoursWorked: Double
    
    var dictionary: [String: Any] {
        [
            "type": type.rawValue,
            "startTime": startTime,
            "endTime": endTime,
            "hoursWorked": hoursWorked
        ]
    }
}

struct Staff: Codable, Identifiable {
    // MARK: - Properties
    @DocumentID var id: String?
    let name: String
    let position: StaffPosition
    var hourlyRate: Double
    let shopId: String
    let shifts: [WorkShift]
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    var monthlyEarnings: Double {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        let monthlyShifts = shifts.filter { shift in
            let shiftMonth = calendar.component(.month, from: shift.startTime)
            let shiftYear = calendar.component(.year, from: shift.startTime)
            return shiftMonth == currentMonth && shiftYear == currentYear
        }
        
        return monthlyShifts.reduce(0) { total, shift in
            total + (shift.hoursWorked * hourlyRate)
        }
    }
    
    var formattedMonthlyEarnings: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: monthlyEarnings)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    // MARK: - Dictionary Representation
    var dictionary: [String: Any] {
        [
            "name": name,
            "position": position.rawValue,
            "hourlyRate": hourlyRate,
            "shopId": shopId,
            "shifts": shifts.map { $0.dictionary },
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

// MARK: - Validation
extension Staff {
    enum ValidationError: LocalizedError {
        case invalidName
        case invalidHourlyRate
        
        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "Tên nhân viên không hợp lệ"
            case .invalidHourlyRate:
                return "Mức lương theo giờ không hợp lệ"
            }
        }
    }
    
    static func validate(name: String, hourlyRate: Double) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidName
        }
        
        guard hourlyRate >= 0 else {
            throw ValidationError.invalidHourlyRate
        }
    }
} 