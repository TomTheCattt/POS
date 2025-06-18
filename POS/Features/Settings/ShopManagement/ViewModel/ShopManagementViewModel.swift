import SwiftUI
import Combine
import FirebaseFirestore

// MARK: - Shop Validation Errors
enum ShopValidationError: LocalizedError {
    case invalidShopName(String)
    case invalidAddress(String)
    case invalidGroundRent(String)
    case invalidBusinessHours(String)
    case invalidPointRate(String)
    case invalidDiscountVoucher(String)
    case exceedMaxShopsLimit(String)
    case missingRequiredFields(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidShopName(let message): return "Lỗi tên cửa hàng: \(message)"
        case .invalidAddress(let message): return "Lỗi địa chỉ: \(message)"
        case .invalidGroundRent(let message): return "Lỗi chi phí mặt bằng: \(message)"
        case .invalidBusinessHours(let message): return "Lỗi giờ hoạt động: \(message)"
        case .invalidPointRate(let message): return "Lỗi tỷ lệ tích điểm: \(message)"
        case .invalidDiscountVoucher(let message): return "Lỗi voucher: \(message)"
        case .exceedMaxShopsLimit(let message): return "Vượt giới hạn: \(message)"
        case .missingRequiredFields(let message): return "Thiếu thông tin: \(message)"
        }
    }
}

@MainActor
final class ShopManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    var activatedShop: Shop?
    var shops: [Shop] = []
    @Published var searchText: String = ""
    @Published var currentView: ViewType = .menu
    @Published var shopName: String = ""
    @Published var address: String = ""
    @Published var groundRent: Double = 0.0
    @Published var currency: Currency = .vnd
    @Published var isActive: Bool = true
    @Published var voucherName: String = ""
    @Published var voucherValue: Double = 0
    @Published var openTime = Date()
    @Published var closeTime = Date()
    @Published var discountVouchers: [DiscountVoucher] = []
    @Published var pointRate: Double = 0
    @Published var isOwnerAuthenticated: Bool = false
    
    // MARK: - Shop Detail Statistics
    @Published private(set) var shopStatistics: [StatisticItem] = []
    @Published private(set) var isLoadingStatistics: Bool = false
    @Published private(set) var selectedShop: Shop?
    
    // MARK: - Validation State
    @Published private(set) var validationErrors: [ShopValidationError] = []
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View State
    enum ViewType {
        case menu
        case inventory
    }
    
    // MARK: - Constants
    private let maxShopNameLength = 100
    private let maxAddressLength = 200
    private let minPointRate: Double = 0.0
    private let maxPointRate: Double = 100.0
    private let minVoucherValue: Double = 0.1
    private let maxVoucherValue: Double = 100.0
    private let maxVoucherNameLength = 50
    
    // MARK: - Computed Properties
    
    var remainingTimeString: String {
        source.remainingTimeString
    }
    
    var isFormValid: Bool {
        validationErrors.isEmpty &&
        !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        groundRent >= 0 &&
        pointRate >= minPointRate && pointRate <= maxPointRate &&
        openTime < closeTime
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        source.currentShopsPublisher
            .sink { [weak self] shops in
                guard let self = self, let shops = shops else { return }
                self.shops = shops
                self.activatedShop = shops.first(where: { $0.isActive })
            }
            .store(in: &cancellables)
        source.isOwnerAuthenticatedPublisher
            .sink { [weak self] rs in
                guard let self = self, let rs = rs else { return }
                self.isOwnerAuthenticated = rs
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    private func validateShop() throws {
        validationErrors.removeAll()
        
        // Validate shop name
        try validateShopName()
        
        // Validate address
        try validateAddress()
        
        // Validate ground rent
        try validateGroundRent()
        
        // Validate business hours
        try validateBusinessHours()
        
        // Validate point rate
        try validatePointRate()
        
        // Validate discount vouchers
        try validateDiscountVouchers()
        
        // Validate max shops limit
        try validateMaxShopsLimit()
        
        if !validationErrors.isEmpty {
            throw validationErrors.first!
        }
    }
    
    private func validateShopName() throws {
        let trimmedName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationErrors.append(.invalidShopName("Tên cửa hàng không được để trống"))
        }
        
        if trimmedName.count < 2 {
            validationErrors.append(.invalidShopName("Tên cửa hàng phải có ít nhất 2 ký tự"))
        }
        
        if trimmedName.count > maxShopNameLength {
            validationErrors.append(.invalidShopName("Tên cửa hàng không được vượt quá \(maxShopNameLength) ký tự"))
        }
        
        // Check for special characters
        if trimmedName.matches(pattern: "^[^a-zA-Z0-9\\s\\u00C0-\\u1EF9]+$") {
            validationErrors.append(.invalidShopName("Tên cửa hàng chứa ký tự không hợp lệ"))
        }
    }
    
    private func validateAddress() throws {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedAddress.isEmpty {
            validationErrors.append(.invalidAddress("Địa chỉ không được để trống"))
        }
        
        if trimmedAddress.count < 5 {
            validationErrors.append(.invalidAddress("Địa chỉ phải có ít nhất 5 ký tự"))
        }
        
        if trimmedAddress.count > maxAddressLength {
            validationErrors.append(.invalidAddress("Địa chỉ không được vượt quá \(maxAddressLength) ký tự"))
        }
    }
    
    private func validateGroundRent() throws {
        if groundRent < 0 {
            validationErrors.append(.invalidGroundRent("Chi phí mặt bằng không được âm"))
        }
        
        if groundRent > 1000000000 { // 1 tỷ
            validationErrors.append(.invalidGroundRent("Chi phí mặt bằng không được vượt quá 1 tỷ"))
        }
    }
    
    private func validateBusinessHours() throws {
        if openTime >= closeTime {
            validationErrors.append(.invalidBusinessHours("Giờ mở cửa phải sớm hơn giờ đóng cửa"))
        }
        
        // Check if business hours are reasonable (at least 1 hour)
        let timeDifference = closeTime.timeIntervalSince(openTime)
        if timeDifference < 3600 { // 1 hour in seconds
            validationErrors.append(.invalidBusinessHours("Giờ hoạt động phải ít nhất 1 giờ"))
        }
        
        if timeDifference > 86400 { // 24 hours in seconds
            validationErrors.append(.invalidBusinessHours("Giờ hoạt động không được vượt quá 24 giờ"))
        }
    }
    
    private func validatePointRate() throws {
        if pointRate < minPointRate {
            validationErrors.append(.invalidPointRate("Tỷ lệ tích điểm không được âm"))
        }
        
        if pointRate > maxPointRate {
            validationErrors.append(.invalidPointRate("Tỷ lệ tích điểm không được vượt quá \(maxPointRate)%"))
        }
    }
    
    private func validateDiscountVouchers() throws {
        for (index, voucher) in discountVouchers.enumerated() {
            // Validate voucher name
            let trimmedName = voucher.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty {
                validationErrors.append(.invalidDiscountVoucher("Tên voucher thứ \(index + 1) không được để trống"))
            }
            
            if trimmedName.count > maxVoucherNameLength {
                validationErrors.append(.invalidDiscountVoucher("Tên voucher thứ \(index + 1) không được vượt quá \(maxVoucherNameLength) ký tự"))
            }
            
            // Validate voucher value
            if voucher.value < minVoucherValue {
                validationErrors.append(.invalidDiscountVoucher("Giá trị voucher thứ \(index + 1) phải lớn hơn \(minVoucherValue)%"))
            }
            
            if voucher.value > maxVoucherValue {
                validationErrors.append(.invalidDiscountVoucher("Giá trị voucher thứ \(index + 1) không được vượt quá \(maxVoucherValue)%"))
            }
        }
        
        // Check for duplicate voucher names
        let voucherNames = discountVouchers.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
        let uniqueNames = Set(voucherNames)
        if voucherNames.count != uniqueNames.count {
            validationErrors.append(.invalidDiscountVoucher("Có voucher trùng tên"))
        }
    }
    
    private func validateMaxShopsLimit() throws {
        guard let userId = source.currentUser?.id else {
            validationErrors.append(.missingRequiredFields("Không tìm thấy thông tin người dùng"))
            return
        }
        
        let userShops = shops.filter { $0.ownerId == userId }
        if userShops.count >= Shop.maxShopsPerUser {
            validationErrors.append(.exceedMaxShopsLimit("Bạn đã đạt giới hạn tối đa \(Shop.maxShopsPerUser) cửa hàng"))
        }
    }
    
    // MARK: - Shop Management Methods
    func canAddNewShop() -> Bool {
        guard let userId = source.currentUser?.id else { return false }
        let userShops = shops.filter { $0.ownerId == userId }
        return userShops.count < Shop.maxShopsPerUser
    }
    
    func createNewShop() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = source.currentUser?.id else {
            throw ShopValidationError.missingRequiredFields("Người dùng chưa đăng nhập")
        }
        
        // Validate before creating
        try validateShop()
        
        do {
            let businessHours = BusinessHours(open: openTime, close: closeTime)
            
            // Create new shop with all properties
            let newShop = Shop(
                shopName: shopName.trimmingCharacters(in: .whitespacesAndNewlines),
                isActive: isActive,
                createdAt: Date(),
                updatedAt: Date(),
                ownerId: userId,
                groundRent: groundRent,
                currency: currency,
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                businessHours: businessHours,
                discountVouchers: discountVouchers.isEmpty ? nil : discountVouchers,
                pointRate: pointRate
            )
            
            // Save to database
            let _ = try await source.environment.databaseService.createShop(newShop, userId: userId)
            
            // Clear form after successful creation
            clearForm()
            
        } catch {
            source.handleError(error)
            throw error
        }
    }
    
    func updateShop(_ shop: Shop) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = source.currentUser?.id,
              let shopId = shop.id else {
            throw ShopValidationError.missingRequiredFields("Thông tin cửa hàng không hợp lệ")
        }
        
        // Validate before updating
        try validateShop()
        
        let businessHours = BusinessHours(open: openTime, close: closeTime)
        
        // Create updated shop
        var updatedShop = shop
        updatedShop.shopName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedShop.isActive = isActive
        updatedShop.updatedAt = Date()
        updatedShop.groundRent = groundRent
        updatedShop.currency = currency
        updatedShop.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedShop.businessHours = businessHours
        updatedShop.discountVouchers = discountVouchers.isEmpty ? nil : discountVouchers
        updatedShop.pointRate = pointRate
        
        // Update in database
        let _ = try await source.environment.databaseService.updateShop(updatedShop, userId: userId, shopId: shopId)
        
        // Clear form after successful update
        clearForm()
    }
    
    func selectShop(_ shop: Shop) async {
        activatedShop = shop
        await source.switchShop(to: shop)
    }
    
    func deleteShop(_ shop: Shop) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                
                guard let shopId = shop.id else {
                    throw AppError.shop(.notFound)
                }
                
                // Delete shop from Firestore
                try await source.environment.databaseService.deleteShop(userId: userId, shopId: shopId)
                
                // Refresh shops list
//                await source.refreshShops()
            }
        } catch {
            source.showAlert(
                title: "Lỗi",
                message: "Không thể xóa cửa hàng: \(error.localizedDescription)",
                primaryButton: AlertButton(title: "OK", role: .cancel)
            )
        }
    }
    
    func loadShopForEditing(_ shop: Shop) {
        shopName = shop.shopName
        address = shop.address
        groundRent = shop.groundRent
        currency = shop.currency
        isActive = shop.isActive
        openTime = shop.businessHours.openTime
        closeTime = shop.businessHours.closeTime
        pointRate = shop.pointRate
        discountVouchers = shop.discountVouchers ?? []
    }
    
    func clearForm() {
        shopName = ""
        address = ""
        groundRent = 0.0
        currency = .vnd
        isActive = true
        openTime = Date()
        closeTime = Date()
        pointRate = 0.0
        discountVouchers = []
        voucherName = ""
        voucherValue = 0
        validationErrors.removeAll()
    }
    
    func toggleView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentView = currentView == .menu ? .inventory : .menu
        }
    }
    
    func addVoucher() {
        // Validate voucher before adding
        let trimmedName = voucherName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            source.showError("Tên voucher không được để trống")
            return
        }
        
        if trimmedName.count > maxVoucherNameLength {
            source.showError("Tên voucher không được vượt quá \(maxVoucherNameLength) ký tự")
            return
        }
        
        if voucherValue < minVoucherValue || voucherValue > maxVoucherValue {
            source.showError("Giá trị voucher phải từ \(minVoucherValue)% đến \(maxVoucherValue)%")
            return
        }
        
        // Check for duplicate names
        if discountVouchers.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedName }) {
            source.showError("Voucher này đã tồn tại")
            return
        }
        
        let newVoucher = DiscountVoucher(name: trimmedName, value: voucherValue)
        discountVouchers.append(newVoucher)
        voucherName = ""
        voucherValue = 0
    }
    
    func removeVoucher(at index: Int) {
        guard index >= 0 && index < discountVouchers.count else { return }
        discountVouchers.remove(at: index)
    }
    
    var searchPlaceholder: String {
        switch currentView {
        case .menu:
            return "Tìm kiếm món..."
        case .inventory:
            return "Tìm kiếm sản phẩm..."
        }
    }
    
    // MARK: - Public Methods
    func getValidationErrors() -> [ShopValidationError] {
        return validationErrors
    }
    
    func clearValidationErrors() {
        validationErrors.removeAll()
    }
}

// MARK: - StatisticItem
struct StatisticItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

// MARK: - Shop Detail Methods
extension ShopManagementViewModel {
    
    // MARK: - Load Shop Statistics
    func loadShopStatistics(for shop: Shop) {
        selectedShop = shop
        Task {
            await loadStatisticsData()
        }
    }
    
    private func loadStatisticsData() async {
        isLoadingStatistics = true
        
        guard let userId = source.currentUser?.id else {
            isLoadingStatistics = false
            return
        }
        
        guard let shop = selectedShop, let shopId = shop.id else {
            isLoadingStatistics = false
            return
        }
        
        do {
            // Load all statistics concurrently
            async let ordersCount = getOrdersCount(userId: userId, shopId: shopId)
            async let todayRevenue = getTodayRevenue(userId: userId, shopId: shopId)
            async let staffCount = getStaffCount(userId: userId, shopId: shopId)
            async let menuCount = getMenuCount(userId: userId, shopId: shopId)
            
            // Wait for all results
            let (orders, revenue, staff, menu) = await (ordersCount, todayRevenue, staffCount, menuCount)
            
            // Create statistics array
            shopStatistics = [
                StatisticItem(
                    title: "Đơn hàng",
                    value: "\(orders)",
                    icon: "cart.fill",
                    color: .blue
                ),
                StatisticItem(
                    title: "Doanh thu hôm nay",
                    value: formatCurrency(revenue),
                    icon: "banknote.fill",
                    color: .green
                ),
                StatisticItem(
                    title: "Nhân viên",
                    value: "\(staff)",
                    icon: "person.2.fill",
                    color: .purple
                ),
                StatisticItem(
                    title: "Thực đơn",
                    value: "\(menu)",
                    icon: "fork.knife",
                    color: .orange
                )
            ]
            
        }
        
        isLoadingStatistics = false
    }
    
    // MARK: - Data Fetching Methods
    private func getOrdersCount(userId: String, shopId: String) async -> Int {
        do {
            let orders: [Order] = try await source.environment.databaseService.getAllOrders(userId: userId, shopId: shopId)
            return orders.count
        } catch {
            return 0
        }
    }
    
    private func getTodayRevenue(userId: String, shopId: String) async -> Double {
        do {
            // Create query for today's revenue
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
            
            let revenueRecords: [RevenueRecord] = try await source.environment.databaseService.getRevenueRecords(userId: userId, shopId: shopId) { query in
                query
                    .whereField("date", isGreaterThanOrEqualTo: today)
                    .whereField("date", isLessThan: tomorrow)
            }
            
            return revenueRecords.reduce(0) { $0 + $1.revenue }
        } catch {
            return 0
        }
    }
    
    private func getStaffCount(userId: String, shopId: String) async -> Int {
        do {
            let staff: [Staff] = try await source.environment.databaseService.getAllStaffs(userId: userId, shopId: shopId)
            return staff.count
        } catch {
            return 0
        }
    }
    
    private func getMenuCount(userId: String, shopId: String) async -> Int {
        do {
            let menu: [AppMenu] = try await source.environment.databaseService.getAllMenu(userId: userId, shopId: shopId)
            return menu.count
        } catch {
            return 0
        }
    }
    
    // MARK: - Helper Methods
    private func formatCurrency(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    // MARK: - Shop Management Methods
    func toggleShopStatus(_ shop: Shop) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await source.withLoading {
                guard let userId = source.currentUser?.id else {
                    throw AppError.auth(.userNotFound)
                }
                
                guard let shopId = shop.id else {
                    throw AppError.shop(.notFound)
                }
                
                // Update shop status
                var updatedShop = shop
                updatedShop.isActive.toggle()
                updatedShop.updatedAt = Date()
                
                let _ = try await source.environment.databaseService.updateShop(updatedShop, userId: userId, shopId: shopId)
                
                // Refresh shops list
//                await source.refreshShops()
                
                // Update selected shop if it's the same
                if selectedShop?.id == shop.id {
                    selectedShop = updatedShop
                }
            }
        } catch {
            source.showAlert(
                title: "Lỗi",
                message: "Không thể cập nhật trạng thái cửa hàng: \(error.localizedDescription)",
                primaryButton: AlertButton(title: "OK", role: .cancel)
            )
        }
    }
}
