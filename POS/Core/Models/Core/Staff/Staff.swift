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
    
    var icon: String {
        switch self {
        case .monday: return "1.circle"
        case .tuesday: return "2.circle"
        case .wednesday: return "3.circle"
        case .thursday: return "4.circle"
        case .friday: return "5.circle"
        case .saturday: return "6.circle"
        case .sunday: return "7.circle"
        }
    }
    
    var weekday: Int {
        switch self {
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        case .sunday: return 1
        }
    }
}

enum StaffPosition: String, Codable, CaseIterable {
    case cashier = "Cashier"
    case waiter = "Waiter"
    case manager = "Manager"
    case barista = "Barista"
    
    var baseHourlyRate: Double {
        switch self {
        case .cashier: return 25000 // VND per hour
        case .waiter: return 22000 // VND per hour
        case .manager: return 35000 // VND per hour
        case .barista: return 28000 // VND per hour
        }
    }
    
    var displayName: String {
        switch self {
        case .cashier: return "Thu ngân"
        case .waiter: return "Phục vụ"
        case .manager: return "Quản lý"
        case .barista: return "Barista"
        }
    }
    
    var icon: String {
        switch self {
        case .cashier: return "creditcard"
        case .waiter: return "person.2"
        case .manager: return "person.badge.key"
        case .barista: return "cup.and.saucer"
        }
    }
    
    var color: String {
        switch self {
        case .cashier: return "green"
        case .waiter: return "blue"
        case .manager: return "purple"
        case .barista: return "orange"
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
    
    var icon: String {
        switch self {
        case .fullTime: return "clock.fill"
        case .partTime: return "clock"
        }
    }
}

struct WorkShift: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let type: WorkShiftType
    let startTime: Date
    let endTime: Date
    let hoursWorked: Double
    let dayOfWeek: DayOfWeek
    
    // MARK: - Computed Properties
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }
    
    var formattedTimeRange: String {
        return "\(formattedStartTime) - \(formattedEndTime)"
    }
    
    var isActive: Bool {
        let now = Date()
        return startTime <= now && now <= endTime
    }
    
    var isUpcoming: Bool {
        return startTime > Date()
    }
    
    var isCompleted: Bool {
        return endTime < Date()
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        type: WorkShiftType,
        startTime: Date,
        endTime: Date,
        hoursWorked: Double,
        dayOfWeek: DayOfWeek
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.hoursWorked = hoursWorked
        self.dayOfWeek = dayOfWeek
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        [
            "id": id,
            "type": type.rawValue,
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "hoursWorked": hoursWorked,
            "dayOfWeek": dayOfWeek.rawValue
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let typeRaw = dictionary["type"] as? String,
              let type = WorkShiftType(rawValue: typeRaw),
              let startTimeTimestamp = dictionary["startTime"] as? Timestamp,
              let endTimeTimestamp = dictionary["endTime"] as? Timestamp,
              let hoursWorked = dictionary["hoursWorked"] as? Double,
              let dayOfWeekRaw = dictionary["dayOfWeek"] as? String,
              let dayOfWeek = DayOfWeek(rawValue: dayOfWeekRaw) else {
            return nil
        }
        
        self.init(
            id: id,
            type: type,
            startTime: startTimeTimestamp.dateValue(),
            endTime: endTimeTimestamp.dateValue(),
            hoursWorked: hoursWorked,
            dayOfWeek: dayOfWeek
        )
    }
}

struct Staff: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let position: StaffPosition
    var hourlyRate: Double
    let shopId: String
    var workShifts: [WorkShift] // Thay cho workSchedule
    let createdAt: Date
    var updatedAt: Date
    var phoneNumber: String?
    
    // MARK: - Computed Properties
    var totalWeeklyHours: Double {
        workShifts.reduce(0) { $0 + $1.hoursWorked }
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
    
    var formattedHourlyRate: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: hourlyRate)) ?? "0"
        return "\(formattedNumber)đ/giờ"
    }
    
    var formattedPhoneNumber: String {
        guard let phoneNumber = phoneNumber else { return "Chưa cập nhật" }
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.count == 10 {
            return "\(cleaned.prefix(3)) \(cleaned.dropFirst(3).prefix(3)) \(cleaned.dropFirst(6))"
        } else if cleaned.count == 11 {
            return "\(cleaned.prefix(4)) \(cleaned.dropFirst(4).prefix(3)) \(cleaned.dropFirst(7))"
        }
        return phoneNumber
    }
    
    var workingDays: [DayOfWeek] {
        let days = Set(workShifts.map { $0.dayOfWeek })
        return Array(days)
    }
    
    var workingDaysCount: Int {
        return workingDays.count
    }
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        name: String,
        position: StaffPosition,
        hourlyRate: Double,
        shopId: String,
        workShifts: [WorkShift] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        phoneNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.hourlyRate = hourlyRate
        self.shopId = shopId
        self.workShifts = workShifts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.phoneNumber = phoneNumber
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "position": position.rawValue,
            "hourlyRate": hourlyRate,
            "shopId": shopId,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if !workShifts.isEmpty {
            dict["workShifts"] = workShifts.map { $0.dictionary }
        }
        
        if let phoneNumber = phoneNumber {
            dict["phoneNumber"] = phoneNumber
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let positionRaw = dictionary["position"] as? String,
              let position = StaffPosition(rawValue: positionRaw),
              let hourlyRate = dictionary["hourlyRate"] as? Double,
              let shopId = dictionary["shopId"] as? String,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        var workShifts: [WorkShift] = []
        if let workShiftsArray = dictionary["workShifts"] as? [[String: Any]] {
            workShifts = workShiftsArray.compactMap { WorkShift(dictionary: $0) }
        }
        
        self.init(
            name: name,
            position: position,
            hourlyRate: hourlyRate,
            shopId: shopId,
            workShifts: workShifts,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            phoneNumber: dictionary["phoneNumber"] as? String
        )
    }
    
    // MARK: - Helper Methods
    func getShiftsForDay(_ day: DayOfWeek) -> [WorkShift] {
        return workShifts.filter { $0.dayOfWeek == day }
    }
    
    func isWorkingDay(_ day: DayOfWeek) -> Bool {
        return !getShiftsForDay(day).isEmpty
    }
    
    func getWorkShiftTypeForDay(_ day: DayOfWeek) -> WorkShiftType? {
        return workShifts.first { $0.dayOfWeek == day }?.type
    }
    
    func getCurrentShift() -> WorkShift? {
        let now = Date()
        return workShifts.first { $0.startTime <= now && now <= $0.endTime }
    }
    
    func getUpcomingShifts() -> [WorkShift] {
        let now = Date()
        return workShifts.filter { $0.startTime > now }
    }
    
    func getCompletedShifts() -> [WorkShift] {
        let now = Date()
        return workShifts.filter { $0.endTime < now }
    }
    
    // MARK: - Mutating Methods
    
    mutating func updatePosition(_ newPosition: StaffPosition) {
        // Note: This would need to be handled in the view model since structs are value types
        updatedAt = Date()
    }
    
    mutating func updateHourlyRate(_ newHourlyRate: Double) {
        hourlyRate = newHourlyRate
        updatedAt = Date()
    }
    
    mutating func updatePhoneNumber(_ newPhoneNumber: String?) {
        phoneNumber = newPhoneNumber
        updatedAt = Date()
    }
    
    mutating func addWorkShift(_ shift: WorkShift) {
        workShifts.append(shift)
        updatedAt = Date()
    }
    
    mutating func removeWorkShift(_ shiftId: String) {
        workShifts.removeAll { $0.id == shiftId }
        updatedAt = Date()
    }
    
    mutating func updateWorkShift(_ shift: WorkShift) {
        if let idx = workShifts.firstIndex(where: { $0.id == shift.id }) {
            workShifts[idx] = shift
            updatedAt = Date()
        }
    }
}

// MARK: - Validation
extension Staff {
    enum ValidationError: LocalizedError {
        case invalidName
        case invalidHourlyRate
        case invalidPhoneNumber
        case invalidWorkShifts
        case duplicateName
        
        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "Tên nhân viên không hợp lệ"
            case .invalidHourlyRate:
                return "Mức lương theo giờ không hợp lệ"
            case .invalidPhoneNumber:
                return "Số điện thoại không hợp lệ"
            case .invalidWorkShifts:
                return "Lịch làm việc không hợp lệ (trùng giờ hoặc vượt quá số ca cho phép)"
            case .duplicateName:
                return "Tên nhân viên đã tồn tại"
            }
        }
    }
    
    func validate() throws {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidName
        }
        
        // Validate hourly rate
        guard hourlyRate >= 0 else {
            throw ValidationError.invalidHourlyRate
        }
        
        guard hourlyRate <= 1000000 else { // Max 1 million VND per hour
            throw ValidationError.invalidHourlyRate
        }
        
        // Validate phone number if provided
        if let phoneNumber = phoneNumber {
            let cleanedPhone = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            guard cleanedPhone.count >= 10 && cleanedPhone.count <= 11 else {
                throw ValidationError.invalidPhoneNumber
            }
        }
        
        // Validate workShifts
        // 1. Không trùng giờ trong cùng 1 ngày
        let groupedByDay = Dictionary(grouping: workShifts, by: { $0.dayOfWeek })
        for (day, shifts) in groupedByDay {
            // Full time: tối đa 1 ca/ngày
            let fullTimeShifts = shifts.filter { $0.type == .fullTime }
            if fullTimeShifts.count > 1 { throw ValidationError.invalidWorkShifts }
            // Part time: tối đa 2 ca/ngày, không trùng giờ
            let partTimeShifts = shifts.filter { $0.type == .partTime }
            if partTimeShifts.count > 2 { throw ValidationError.invalidWorkShifts }
            // Kiểm tra trùng giờ giữa các ca part time
            for i in 0..<partTimeShifts.count {
                for j in (i+1)..<partTimeShifts.count {
                    let a = partTimeShifts[i], b = partTimeShifts[j]
                    if a.startTime < b.endTime && b.startTime < a.endTime {
                        throw ValidationError.invalidWorkShifts
                    }
                }
            }
            // Kiểm tra trùng giờ giữa part time và full time (nếu có)
            if let full = fullTimeShifts.first {
                for part in partTimeShifts {
                    if full.startTime < part.endTime && part.startTime < full.endTime {
                        throw ValidationError.invalidWorkShifts
                    }
                }
            }
        }
    }
    
    static func validateName(_ name: String, existingStaff: [Staff], excludeId: String? = nil) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidName
        }
        
        // Check for duplicate names
        let duplicateExists = existingStaff.contains { staff in
            staff.name.lowercased() == trimmedName.lowercased() && staff.id != excludeId
        }
        
        if duplicateExists {
            throw ValidationError.duplicateName
        }
    }
} 

