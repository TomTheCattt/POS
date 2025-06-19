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
    
    // MARK: - Work Shift States
    @Published var workShifts: [WorkShift] = [] // Mảng ca làm việc duy nhất
    @Published var expandedDay: DayOfWeek? = nil
    
    // MARK: - Staff List States
    @Published var selectedStaff: Staff?
    @Published var showingSearchBar = false
    @Published var searchText = ""
    @Published var selectedPosition: StaffPosition?
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
    var totalWeeklyHours: Double {
        workShifts.reduce(0) { $0 + $1.hoursWorked }
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
        
        guard let rate = Double(hourlyRate), rate >= minHourlyRate, rate <= maxHourlyRate else {
            validationErrors.append(.invalidHourlyRate("Mức lương theo giờ không hợp lệ"))
            return
        }
        
        if totalWeeklyHours < minWeeklyHours {
            validationErrors.append(.invalidWorkShift("Tổng giờ làm việc phải ít nhất \(minWeeklyHours) giờ/tuần"))
        }
        
        if totalWeeklyHours > maxWeeklyHours {
            validationErrors.append(.invalidWorkShift("Tổng giờ làm việc không được vượt quá \(maxWeeklyHours) giờ/tuần"))
        }
        
        // Validate workShifts logic như trong struct Staff
        do {
            try Staff(
                name: name,
                position: position,
                hourlyRate: rate,
                shopId: "shopId",
                workShifts: workShifts
            ).validate()
        } catch let error as Staff.ValidationError {
            switch error {
            case .invalidWorkShifts:
                validationErrors.append(.invalidWorkShift(error.localizedDescription))
            default:
                break
            }
        }
        
        if !validationErrors.isEmpty {
            throw validationErrors.first!
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
    }
    
    func showDeleteAlert(for staff: Staff) {
        selectedStaff = staff
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
        workShifts = []
        expandedDay = nil
        editingStaff = nil
        validationErrors.removeAll()
    }
    
    func loadStaffData(_ staff: Staff) {
        editingStaff = staff
        name = staff.name
        position = staff.position
        hourlyRate = String(format: "%.0f", staff.hourlyRate)
        workShifts = staff.workShifts
    }
    
    // MARK: - Work Shift Management
    func getShiftsForDay(_ day: DayOfWeek) -> [WorkShift] {
        workShifts.filter { $0.dayOfWeek == day }
    }
    
    func addWorkShift(_ shift: WorkShift) {
        workShifts.append(shift)
    }
    
    func removeWorkShift(_ shiftId: String) {
        workShifts.removeAll { $0.id == shiftId }
    }
    
    func updateWorkShift(_ shift: WorkShift) {
        if let idx = workShifts.firstIndex(where: { $0.id == shift.id }) {
            workShifts[idx] = shift
        }
    }
    
    func isWorkingDay(_ day: DayOfWeek) -> Bool {
        !getShiftsForDay(day).isEmpty
    }
    
    // MARK: - Database Operations
    func createStaff(for shop: Shop) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            try validateStaff()
            let staff = Staff(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                position: position,
                hourlyRate: Double(hourlyRate) ?? 0,
                shopId: "shopId", // Cần truyền đúng shopId thực tế
                workShifts: workShifts,
                createdAt: Date(),
                updatedAt: Date()
            )
            let _ = try await source.environment.databaseService.createStaff(staff, userId: source.userId, shopId: shop.id!)
            resetForm()
        } catch {
            // Xử lý lỗi
            throw error
        }
    }
    
    func updateStaff(_ staff: Staff, for shop: Shop) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            try validateStaff()
            let updatedStaff = Staff(
                id: staff.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                position: position,
                hourlyRate: Double(hourlyRate) ?? 0,
                shopId: staff.shopId,
                workShifts: workShifts,
                createdAt: staff.createdAt,
                updatedAt: Date()
            )
            try await source.environment.databaseService.updateStaff(updatedStaff, userId: source.userId, shopId: shop.id!, staffId: staff.id!)
            resetForm()
        } catch {
            // Xử lý lỗi
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
    
    func saveStaff(for shop: Shop) async {
        do {
            if let editingStaff = editingStaff {
                // Update existing staff
                try await updateStaff(editingStaff, for: shop)
            } else {
                // Create new staff
                try await createStaff(for: shop)
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
