import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

// MARK: - Staff Validation Errors
enum StaffValidationError: LocalizedError {
    case invalidName(String)
    case invalidHourlyRate(String)
    case invalidWorkSchedule(String)
    case invalidWorkShift(String)
    case missingRequiredFields(String)
    case duplicateStaff(String)
    case exceedMaxStaffLimit(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName(let message): return "Lỗi tên nhân viên: \(message)"
        case .invalidHourlyRate(let message): return "Lỗi mức lương: \(message)"
        case .invalidWorkSchedule(let message): return "Lỗi lịch làm việc: \(message)"
        case .invalidWorkShift(let message): return "Lỗi ca làm việc: \(message)"
        case .missingRequiredFields(let message): return "Thiếu thông tin: \(message)"
        case .duplicateStaff(let message): return "Trùng lặp: \(message)"
        case .exceedMaxStaffLimit(let message): return "Vượt giới hạn: \(message)"
        }
    }
}

@MainActor
class StaffViewModel: ObservableObject {
    @Published var staffList: [Staff] = []
    
    // MARK: - Form States
    @Published var name = ""
    @Published var position = StaffPosition.cashier
    @Published var hourlyRate = ""
    @Published var isLoading = false
    
    // MARK: - Work Schedule States
    @Published var workSchedule: [DayOfWeek: [WorkShift]] = [:]
    @Published var workingDays: Set<DayOfWeek> = []
    @Published var selectedWorkShiftTypes: [DayOfWeek: WorkShiftType] = [:]
    @Published var expandedDay: DayOfWeek?
    @Published var selectedShifts: [DayOfWeek: Set<String>] = [:]
    
    // MARK: - Staff List States
    @Published var showingAddStaffSheet = false
    @Published var selectedStaff: Staff?
    @Published var showingSearchBar = false
    @Published var searchText = ""
    @Published var selectedPosition: StaffPosition?
    @Published var showingDeleteAlert = false
    @Published var animateHeader = false
    
    // MARK: - Validation State
    @Published private(set) var validationErrors: [StaffValidationError] = []
    
    // MARK: - Staff for editing
    private var editingStaff: Staff?
    
    // MARK: - Constants
    private let maxStaffPerShop = 20
    private let maxNameLength = 100
    private let minNameLength = 2
    private let minHourlyRate: Double = 15000 // 15k VND/hour
    private let maxHourlyRate: Double = 500000 // 500k VND/hour
    private let maxWeeklyHours: Double = 60 // 60 hours/week
    private let minWeeklyHours: Double = 4 // 4 hours/week
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        validationErrors.isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= minNameLength &&
        name.trimmingCharacters(in: .whitespacesAndNewlines).count <= maxNameLength &&
        (Double(hourlyRate) ?? 0) >= minHourlyRate &&
        (Double(hourlyRate) ?? 0) <= maxHourlyRate &&
        totalWeeklyHours >= minWeeklyHours &&
        totalWeeklyHours <= maxWeeklyHours &&
        !workingDays.isEmpty
    }
    
    var totalWeeklyHours: Double {
        var total = 0.0
        for day in workingDays {
            let selectedShiftsForDay = getSelectedShiftsForDay(day)
            total += selectedShiftsForDay.reduce(0) { $0 + $1.hoursWorked }
        }
        return total
    }
    
    var estimatedMonthlySalary: Double {
        let weeklyHours = totalWeeklyHours
        let hourlyRateValue = Double(hourlyRate) ?? 0
        return weeklyHours * hourlyRateValue * 4.33
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
    
    var filteredStaff: [Staff] {
        var result = staffList
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let position = selectedPosition {
            result = result.filter { $0.position == position }
        }
        
        return result
    }
    
    var totalMonthlyPayroll: Double {
        filteredStaff.reduce(0) { $0 + $1.estimatedMonthlySalary }
    }
    
    var formattedTotalMonthlyPayroll: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: totalMonthlyPayroll)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBinding()
    }
    
    func setupBinding() {
        source.staffsPublisher
            .sink { [weak self] staffs in
                guard let self = self,
                      let staffs = staffs else { return }
                self.staffList = staffs
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    private func validateStaff() throws {
        validationErrors.removeAll()
        
        // Validate name
        try validateName()
        
        // Validate hourly rate
        try validateHourlyRate()
        
        // Validate work schedule
        try validateWorkSchedule()
        
        // Validate work shifts
        try validateWorkShifts()
        
        // Validate max staff limit
        try validateMaxStaffLimit()
        
        // Validate duplicate staff
        try validateDuplicateStaff()
        
        if !validationErrors.isEmpty {
            throw validationErrors.first!
        }
    }
    
    private func validateName() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationErrors.append(.invalidName("Tên nhân viên không được để trống"))
        }
        
        if trimmedName.count < minNameLength {
            validationErrors.append(.invalidName("Tên nhân viên phải có ít nhất \(minNameLength) ký tự"))
        }
        
        if trimmedName.count > maxNameLength {
            validationErrors.append(.invalidName("Tên nhân viên không được vượt quá \(maxNameLength) ký tự"))
        }
        
        // Check for special characters (allow Vietnamese characters)
        if trimmedName.matches(pattern: "^[^a-zA-Z0-9\\s\\u00C0-\\u1EF9]+$") {
            validationErrors.append(.invalidName("Tên nhân viên chứa ký tự không hợp lệ"))
        }
        
        // Check for numbers only
        if trimmedName.matches(pattern: "^[0-9]+$") {
            validationErrors.append(.invalidName("Tên nhân viên không được chỉ chứa số"))
        }
    }
    
    private func validateHourlyRate() throws {
        guard let rate = Double(hourlyRate) else {
            validationErrors.append(.invalidHourlyRate("Mức lương theo giờ không hợp lệ"))
            return
        }
        
        if rate < minHourlyRate {
            validationErrors.append(.invalidHourlyRate("Mức lương tối thiểu là \(formatCurrency(minHourlyRate))/giờ"))
        }
        
        if rate > maxHourlyRate {
            validationErrors.append(.invalidHourlyRate("Mức lương tối đa là \(formatCurrency(maxHourlyRate))/giờ"))
        }
    }
    
    private func validateWorkSchedule() throws {
        if workingDays.isEmpty {
            validationErrors.append(.invalidWorkSchedule("Phải chọn ít nhất một ngày làm việc"))
        }
        
        if totalWeeklyHours < minWeeklyHours {
            validationErrors.append(.invalidWorkSchedule("Tổng giờ làm việc phải ít nhất \(minWeeklyHours) giờ/tuần"))
        }
        
        if totalWeeklyHours > maxWeeklyHours {
            validationErrors.append(.invalidWorkSchedule("Tổng giờ làm việc không được vượt quá \(maxWeeklyHours) giờ/tuần"))
        }
    }
    
    private func validateWorkShifts() throws {
        for day in workingDays {
            let selectedShiftsForDay = getSelectedShiftsForDay(day)
            
            if selectedShiftsForDay.isEmpty {
                validationErrors.append(.invalidWorkShift("Ngày \(day.rawValue) phải có ít nhất một ca làm việc"))
                continue
            }
            
            // Check for overlapping shifts
            let sortedShifts = selectedShiftsForDay.sorted { $0.startTime < $1.startTime }
            for i in 0..<(sortedShifts.count - 1) {
                let currentShift = sortedShifts[i]
                let nextShift = sortedShifts[i + 1]
                
                if currentShift.endTime > nextShift.startTime {
                    validationErrors.append(.invalidWorkShift("Ca làm việc ngày \(day.rawValue) bị chồng lấp"))
                    break
                }
            }
            
            // Check shift duration
            for shift in selectedShiftsForDay {
                let duration = shift.endTime.timeIntervalSince(shift.startTime) / 3600 // hours
                
                if duration < 1 {
                    validationErrors.append(.invalidWorkShift("Ca làm việc phải ít nhất 1 giờ"))
                }
                
                if duration > 12 {
                    validationErrors.append(.invalidWorkShift("Ca làm việc không được vượt quá 12 giờ"))
                }
            }
        }
    }
    
    private func validateMaxStaffLimit() throws {
        if staffList.count >= maxStaffPerShop {
            validationErrors.append(.exceedMaxStaffLimit("Đã đạt giới hạn tối đa \(maxStaffPerShop) nhân viên"))
        }
    }
    
    private func validateDuplicateStaff() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingStaff = staffList.first { staff in
            staff.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedName.lowercased() &&
            staff.id != editingStaff?.id
        }
        
        if existingStaff != nil {
            validationErrors.append(.duplicateStaff("Đã có nhân viên tên '\(trimmedName)'"))
        }
    }
    
    // MARK: - Staff List Management
    func setupStaffsListener(shopId: String) {
        source.setupStaffsListener(shopId: shopId)
    }
    
    func removeStaffsListener(shopId: String) {
        source.removeStaffsListener(shopId: shopId)
    }
    
    func toggleSearchBar() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingSearchBar.toggle()
        }
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func selectPosition(_ position: StaffPosition?) {
        selectedPosition = position
    }
    
    func selectStaff(_ staff: Staff?) {
        selectedStaff = staff
    }
    
    func showAddStaffSheet(for staff: Staff? = nil) {
        selectedStaff = staff
        if let staff = staff {
            loadStaffData(staff)
        } else {
            resetForm()
        }
        showingAddStaffSheet = true
    }
    
    func showDeleteAlert(for staff: Staff) {
        selectedStaff = staff
        showingDeleteAlert = true
    }
    
    func startHeaderAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateHeader = true
        }
    }
    
    func formatCurrency(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    // MARK: - Form Management
    func resetForm() {
        name = ""
        position = .cashier
        hourlyRate = ""
        workSchedule = [:]
        workingDays = []
        selectedWorkShiftTypes = [:]
        expandedDay = nil
        selectedShifts = [:]
        editingStaff = nil
        validationErrors.removeAll()
    }
    
    func loadStaffData(_ staff: Staff) {
        editingStaff = staff
        name = staff.name
        position = staff.position
        hourlyRate = String(format: "%.0f", staff.hourlyRate)
        workSchedule = staff.workSchedule
        
        // Khôi phục trạng thái làm việc
        workingDays = []
        selectedWorkShiftTypes = [:]
        selectedShifts = [:]
        
        for day in DayOfWeek.allCases {
            if staff.isWorkingDay(day) {
                workingDays.insert(day)
                if let shiftType = staff.getWorkShiftTypeForDay(day) {
                    selectedWorkShiftTypes[day] = shiftType
                }
                // Mặc định chọn ca đầu tiên
                if let firstShift = staff.workSchedule[day]?.first {
                    selectedShifts[day] = [firstShift.id]
                }
            }
        }
    }
    
    // MARK: - Work Schedule Management
    func toggleWorkingDay(_ day: DayOfWeek, isWorking: Bool) {
        if isWorking {
            workingDays.insert(day)
        } else {
            workingDays.remove(day)
            selectedWorkShiftTypes.removeValue(forKey: day)
            workSchedule.removeValue(forKey: day)
            selectedShifts.removeValue(forKey: day)
        }
    }
    
    func updateWorkShiftTypeForDay(_ day: DayOfWeek, shiftType: WorkShiftType) {
        selectedWorkShiftTypes[day] = shiftType
        let suggestedShifts = generateSuggestedShifts(for: shiftType, day: day)
        workSchedule[day] = suggestedShifts
        
        // Reset selected shifts for this day
        selectedShifts[day] = []
    }
    
    func toggleExpandedDay(_ day: DayOfWeek) {
        if expandedDay == day {
            expandedDay = nil
        } else {
            expandedDay = day
            // Tự động thêm ngày vào workingDays nếu chưa có
            if !workingDays.contains(day) {
                workingDays.insert(day)
                selectedWorkShiftTypes[day] = .fullTime
                let suggestedShifts = generateSuggestedShifts(for: .fullTime, day: day)
                workSchedule[day] = suggestedShifts
                // Mặc định chọn ca đầu tiên
                if let firstShift = suggestedShifts.first {
                    selectedShifts[day] = [firstShift.id]
                }
            }
        }
    }
    
    func updateShiftsForDay(_ day: DayOfWeek, shifts: [WorkShift]) {
        workSchedule[day] = shifts
    }
    
    func toggleShiftSelection(_ shift: WorkShift, day: DayOfWeek) {
        let shiftId = shift.id
        var currentSelected = selectedShifts[day] ?? []
        
        if currentSelected.contains(shiftId) {
            currentSelected.remove(shiftId)
        } else {
            // Nếu là ca fullTime, chỉ cho phép chọn 1 ca
            if shift.type == .fullTime {
                currentSelected = [shiftId]
            } else {
                currentSelected.insert(shiftId)
            }
        }
        
        selectedShifts[day] = currentSelected
    }
    
    func isShiftSelected(_ shift: WorkShift, day: DayOfWeek) -> Bool {
        let shiftId = shift.id
        return selectedShifts[day]?.contains(shiftId) ?? false
    }
    
    func getSelectedShiftsForDay(_ day: DayOfWeek) -> [WorkShift] {
        let selectedIds = selectedShifts[day] ?? []
        return (workSchedule[day] ?? []).filter { shift in
            selectedIds.contains(shift.id)
        }
    }
    
    // MARK: - Helper Methods
    private func generateSuggestedShifts(for shiftType: WorkShiftType, day: DayOfWeek) -> [WorkShift] {
        var shifts: [WorkShift] = []
        let calendar = Calendar.current
        let today = Date()
        
        switch shiftType {
        case .fullTime:
            // Ca sáng: 8:00-16:00
            var morningComponents = calendar.dateComponents([.year, .month, .day], from: today)
            morningComponents.hour = 8
            morningComponents.minute = 0
            let morningStart = calendar.date(from: morningComponents) ?? today
            
            morningComponents.hour = 16
            morningComponents.minute = 0
            let morningEnd = calendar.date(from: morningComponents) ?? today
            
            shifts.append(WorkShift(
                id: UUID().uuidString,
                type: .fullTime,
                startTime: morningStart,
                endTime: morningEnd,
                hoursWorked: 8.0,
                dayOfWeek: day
            ))
            
            // Ca chiều: 15:00-23:00
            var eveningComponents = calendar.dateComponents([.year, .month, .day], from: today)
            eveningComponents.hour = 15
            eveningComponents.minute = 0
            let eveningStart = calendar.date(from: eveningComponents) ?? today
            
            eveningComponents.hour = 23
            eveningComponents.minute = 0
            let eveningEnd = calendar.date(from: eveningComponents) ?? today
            
            shifts.append(WorkShift(
                id: UUID().uuidString,
                type: .fullTime,
                startTime: eveningStart,
                endTime: eveningEnd,
                hoursWorked: 8.0,
                dayOfWeek: day
            ))
            
        case .partTime:
            // Ca sáng: 8:00-12:00
            var morningComponents = calendar.dateComponents([.year, .month, .day], from: today)
            morningComponents.hour = 8
            morningComponents.minute = 0
            let morningStart = calendar.date(from: morningComponents) ?? today
            
            morningComponents.hour = 12
            morningComponents.minute = 0
            let morningEnd = calendar.date(from: morningComponents) ?? today
            
            shifts.append(WorkShift(
                id: UUID().uuidString,
                type: .partTime,
                startTime: morningStart,
                endTime: morningEnd,
                hoursWorked: 4.0,
                dayOfWeek: day
            ))
            
            // Ca trưa: 12:00-16:00
            var noonComponents = calendar.dateComponents([.year, .month, .day], from: today)
            noonComponents.hour = 12
            noonComponents.minute = 0
            let noonStart = calendar.date(from: noonComponents) ?? today
            
            noonComponents.hour = 16
            noonComponents.minute = 0
            let noonEnd = calendar.date(from: noonComponents) ?? today
            
            shifts.append(WorkShift(
                id: UUID().uuidString,
                type: .partTime,
                startTime: noonStart,
                endTime: noonEnd,
                hoursWorked: 4.0,
                dayOfWeek: day
            ))
            
            // Ca chiều: 16:00-20:00
            var eveningComponents = calendar.dateComponents([.year, .month, .day], from: today)
            eveningComponents.hour = 16
            eveningComponents.minute = 0
            let eveningStart = calendar.date(from: eveningComponents) ?? today
            
            eveningComponents.hour = 20
            eveningComponents.minute = 0
            let eveningEnd = calendar.date(from: eveningComponents) ?? today
            
            shifts.append(WorkShift(
                id: UUID().uuidString,
                type: .partTime,
                startTime: eveningStart,
                endTime: eveningEnd,
                hoursWorked: 4.0,
                dayOfWeek: day
            ))
            
            // Ca tối: 19:00-23:00
            var nightComponents = calendar.dateComponents([.year, .month, .day], from: today)
            nightComponents.hour = 19
            nightComponents.minute = 0
            let nightStart = calendar.date(from: nightComponents) ?? today
            
            nightComponents.hour = 23
            nightComponents.minute = 0
            let nightEnd = calendar.date(from: nightComponents) ?? today
            
            shifts.append(WorkShift(
                id: UUID().uuidString,
                type: .partTime,
                startTime: nightStart,
                endTime: nightEnd,
                hoursWorked: 4.0,
                dayOfWeek: day
            ))
        }
        
        return shifts
    }
    
    // MARK: - Database Operations
    func createStaff(name: String, position: StaffPosition, hourlyRate: Double, workSchedule: [DayOfWeek: [WorkShift]]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate before creating
            try validateStaff()
            
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                guard let shopId = source.activatedShop?.id else {
                    throw AppError.shop(.notFound)
                }
                
                // Create new staff
                let staff = Staff(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    position: position,
                    hourlyRate: hourlyRate,
                    shopId: shopId,
                    workSchedule: workSchedule,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                // Save to Firestore
                let _ = try await source.environment.databaseService.createStaff(staff, userId: userId, shopId: shopId)
                
                // Clear form after successful creation
                resetForm()
            }
        } catch {
            source.handleError(error)
            throw error
        }
    }
    
    func updateStaff(_ staff: Staff, name: String, position: StaffPosition, hourlyRate: Double, workSchedule: [DayOfWeek: [WorkShift]]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate before updating
            try validateStaff()
            
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                guard let shopId = source.activatedShop?.id else {
                    throw AppError.shop(.notFound)
                }
                
                guard let staffId = staff.id else { return }
                
                let updatedStaff = Staff(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    position: position,
                    hourlyRate: hourlyRate,
                    shopId: shopId,
                    workSchedule: workSchedule,
                    createdAt: staff.createdAt,
                    updatedAt: Date()
                )
                
                let _ = try await source.environment.databaseService.updateStaff(updatedStaff, userId: userId, shopId: shopId, staffId: staffId)
                
                // Clear form after successful update
                resetForm()
            }
        } catch {
            source.handleError(error)
            throw error
        }
    }
    
    func deleteStaff(_ staff: Staff) async throws {
        guard let staffId = staff.id else { return }
        do {
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                guard let shopId = source.activatedShop?.id else {
                    throw AppError.shop(.notFound)
                }
                try await source.environment.databaseService.deleteStaff(userId: userId, shopId: shopId, staffId: staffId)
            }
        } catch {
            source.handleError(error)
            throw error
        }
    }
    
    func saveStaff() async {
        guard let rate = Double(hourlyRate) else { return }
        
        // Tạo workSchedule từ selected shifts
        var finalWorkSchedule: [DayOfWeek: [WorkShift]] = [:]
        for day in workingDays {
            let selectedShiftsForDay = getSelectedShiftsForDay(day)
            if !selectedShiftsForDay.isEmpty {
                finalWorkSchedule[day] = selectedShiftsForDay
            }
        }
        
        do {
            if let editingStaff = editingStaff {
                // Update existing staff
                try await updateStaff(
                    editingStaff,
                    name: name,
                    position: position,
                    hourlyRate: rate,
                    workSchedule: finalWorkSchedule
                )
            } else {
                // Create new staff
                try await createStaff(
                    name: name,
                    position: position,
                    hourlyRate: rate,
                    workSchedule: finalWorkSchedule
                )
            }
        } catch {
            // Error is already handled in the methods above
        }
    }
    
    // MARK: - Public Methods
    func getValidationErrors() -> [StaffValidationError] {
        return validationErrors
    }
    
    func clearValidationErrors() {
        validationErrors.removeAll()
    }
}
