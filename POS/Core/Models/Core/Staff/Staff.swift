import Foundation
import FirebaseFirestore

enum DayOfWeek: String, CaseIterable, Codable {
    case monday = "Thứ 2"
    case tuesday = "Thứ 3"
    case wednesday = "Thứ 4"
    case thursday = "Thứ 5"
    case friday = "Thứ 6"
    case saturday = "Thứ 7"
    case sunday = "Chủ nhật"
    
    var shortName: String {
        switch self {
        case .monday: return "T2"
        case .tuesday: return "T3"
        case .wednesday: return "T4"
        case .thursday: return "T5"
        case .friday: return "T6"
        case .saturday: return "T7"
        case .sunday: return "CN"
        }
    }
}

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

enum WorkShiftType: String, Codable, CaseIterable {
    case fullTime = "Full-time"
    case partTime = "Part-time"
    
    var hoursPerShift: Double {
        switch self {
        case .fullTime: return 8.0
        case .partTime: return 4.0
        }
    }
    
    var maxShiftsPerDay: Int {
        switch self {
        case .fullTime: return 1
        case .partTime: return 2
        }
    }
    
    var displayName: String {
        switch self {
        case .fullTime: return "Toàn thời gian"
        case .partTime: return "Bán thời gian"
        }
    }
}

struct Staff: Codable, Identifiable {
    // MARK: - Properties
    @DocumentID var id: String?
    let name: String
    let position: StaffPosition
    var hourlyRate: Double
    let shopId: String
    var workSchedule: [DayOfWeek: [WorkShift]] // Thay đổi từ shifts sang workSchedule
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    var totalWeeklyHours: Double {
        workSchedule.values.flatMap { $0 }.reduce(0) { total, shift in
            total + shift.hoursWorked
        }
    }
    
    var estimatedMonthlySalary: Double {
        // Tính lương tháng dựa trên 4.33 tuần/tháng (52 tuần/12 tháng)
        return totalWeeklyHours * hourlyRate * 4.33
    }
    
    var formattedEstimatedMonthlySalary: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: estimatedMonthlySalary)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    var formattedWeeklyHours: String {
        return String(format: "%.1f tiếng/tuần", totalWeeklyHours)
    }
    
    // MARK: - Helper Methods
    func getShiftsForDay(_ day: DayOfWeek) -> [WorkShift] {
        return workSchedule[day] ?? []
    }
    
    func isWorkingDay(_ day: DayOfWeek) -> Bool {
        return !(workSchedule[day]?.isEmpty ?? true)
    }
    
    func getWorkShiftTypeForDay(_ day: DayOfWeek) -> WorkShiftType? {
        return workSchedule[day]?.first?.type
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
