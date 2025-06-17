import SwiftUI
import Combine

@MainActor
final class OrderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var selectedItems: [OrderItem] = []
    @Published private(set) var searchKey: String = ""
    @Published private(set) var selectedCategory: String = "All"
    @Published private(set) var menuItems: [MenuItem] = []
    @Published private(set) var categories: [String] = ["All"]
    @Published private(set) var paymentMethod: PaymentMethod = .cash
    @Published private(set) var ingredientAlerts: [IngredientAlert] = []
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var dragOffset: CGFloat = 0
    
    @Published var selectedCustomer: Customer?
    @Published var selectedDiscount: DiscountVoucher?
    @Published var isSearchingCustomer: Bool = false
    @Published var showingDeleteButton: Bool = false
    @Published var orderItemOffset: CGFloat = 0
    
    // Thêm các thuộc tính mới cho tìm kiếm
    @Published var menuSearchKey: String = ""
    @Published var customerSearchKey: String = ""
    @Published var isSearchingMenu: Bool = false
    @Published var isSearchingCustomers: Bool = false
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var totalPrice: String {
        let total = selectedItems.reduce(0) { result, item in
            result + (item.price * Double(item.quantity))
        }
        return "$\(String(format: "%.2f", total))"
    }
    
    var filteredMenuItems: [MenuItem] {
        menuItems.filter {
            (selectedCategory == "All" || $0.category == selectedCategory) &&
            (menuSearchKey.isEmpty || $0.name.localizedCaseInsensitiveContains(menuSearchKey))
        }
    }
    
    var searchedCustomers: [Customer] {
        guard !customerSearchKey.isEmpty else { return [] }
        return customers.filter { customer in
            customer.name.localizedCaseInsensitiveContains(customerSearchKey) ||
            customer.phoneNumber.localizedCaseInsensitiveContains(customerSearchKey)
        }
    }
    
    var subtotal: Double {
        selectedItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var discount: Double {
        guard let selectedDiscount = selectedDiscount else { return 0 }
        return subtotal * (selectedDiscount.value / 100)
    }
    
    var total: Double {
        subtotal - discount
    }
    
    // MARK: - Category Methods
    func getCategoryIcon(for category: String) -> String {
        if let suggestedCategory = findSuggestedCategory(for: category) {
            return suggestedCategory.icon
        }
        return "circle.fill" // Icon mặc định
    }
    
    func getCategoryColor(for category: String) -> Color {
        if let suggestedCategory = findSuggestedCategory(for: category) {
            return suggestedCategory.color
        }
        return .teal // Màu mặc định
    }
    
    func isCategorySelected(_ category: String) -> Bool {
        return selectedCategory == category
    }
    
    private func updateCategories(from items: [MenuItem]) {
        var uniqueCategories = Set(items.map { $0.category })
        uniqueCategories.insert("All")
        categories = Array(uniqueCategories).sorted()
    }
    
    private func findSuggestedCategory(for category: String) -> SuggestedCategories? {
        return SuggestedCategories.allCases.first { suggestedCategory in
            suggestedCategory.rawValue.lowercased() == category.lowercased()
        }
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        source.menuItemsPublisher
            .sink { [weak self] menuItems in
                guard let self = self,
                      let menuItems = menuItems else { return }
                self.menuItems = menuItems
                self.updateCategories(from: menuItems)
            }
            .store(in: &cancellables)
        source.customersPublisher
            .sink { [weak self] customers in
                guard let self = self,
                      let customers = customers else { return }
                self.customers = customers
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Customer Methods
    func selectCustomer(_ customer: Customer) {
        selectedCustomer = customer
        searchKey = ""
    }
    
    func clearSelectedCustomer() {
        selectedCustomer = nil
    }
    
    // MARK: - Discount Methods
    func selectDiscount(_ discount: DiscountVoucher) {
        if selectedDiscount?.name == discount.name {
            // Nếu đang chọn và bấm lại => huỷ chọn
            selectedDiscount = nil
        } else {
            selectedDiscount = discount
        }
    }
    
    // MARK: - Public Methods
    func updateSearchKey(_ newValue: String) {
        searchKey = newValue
    }
    
    func updateSelectedCategory(_ category: String) {
        selectedCategory = category
    }
    
    func updatePaymentMethod(_ paymentMethod: PaymentMethod) {
        self.paymentMethod = paymentMethod
    }
    
    func createCustomer(name: String, phoneNumber: String, gender: Gender) async {
        let customer = Customer(name: name, phoneNumber: phoneNumber, point: 0, gender: gender)
        Task {
            try await source.environment.databaseService.createCustomer(customer, userId: source.userId, shopId: source.activatedShop?.id ?? "")
        }
    }
    
    func addItemToOrder(_ item: MenuItem, _ temperature: TemperatureOption, _ consumption: ConsumptionOption) {
        if let index = selectedItems.firstIndex(where: {
            $0.name == item.name &&
            $0.price == item.price &&
            $0.temperature == temperature &&
            $0.consumption == consumption
        }) {
            var updatedItems = selectedItems
            var updatedItem = updatedItems[index]
            updatedItem.quantity += 1
            updatedItems[index] = updatedItem
            selectedItems = updatedItems
        } else {
            selectedItems.append(OrderItem(
                id: UUID().uuidString,
                menuItemId: item.id ?? "",
                name: item.name,
                quantity: 1,
                price: item.price,
                temperature: temperature,
                consumption: consumption
            ))
        }
    }
    
    func updateOrderItemNote(for itemId: String, note: String) {
        if let index = selectedItems.firstIndex(where: { $0.id == itemId }) {
            var updatedItems = selectedItems
            var updatedItem = updatedItems[index]
            updatedItem.note = note
            updatedItems[index] = updatedItem
            selectedItems = updatedItems
            objectWillChange.send()
        }
    }
    
    func updateOrderItemQuantity(for itemId: String, increment: Bool) {
        if let index = selectedItems.firstIndex(where: { $0.id == itemId }) {
            var updatedItems = selectedItems
            var updatedItem = updatedItems[index]
            
            if increment {
                updatedItem.quantity += 1
                updatedItems[index] = updatedItem
            } else {
                updatedItem.quantity -= 1
                if updatedItem.quantity <= 0 {
                    updatedItems.remove(at: index)
                } else {
                    updatedItems[index] = updatedItem
                }
            }
            
            selectedItems = updatedItems
            objectWillChange.send()
        }
    }
    
    func removeOrderItem(itemId: String) {
        selectedItems.removeAll { $0.id == itemId }
        objectWillChange.send()
    }
    
    func clearOrder() {
        selectedItems.removeAll()
        selectedCustomer = nil
        selectedDiscount = nil
        paymentMethod = .cash
        objectWillChange.send()
    }
    
    func createOrder() async throws {
        guard let userId = source.currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = source.activatedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let newOrder = Order(
            items: selectedItems,
            discount: discount,
            totalAmount: total,
            paymentMethod: paymentMethod,
            customer: selectedCustomer,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await source.withLoading {
                // Kiểm tra và cập nhật số lượng nguyên liệu
                try await updateIngredientUsage(for: newOrder)
                
                // Tạo đơn hàng mới
                let createdOrderId = try await source.environment.databaseService.createOrder(
                    newOrder,
                    userId: userId,
                    shopId: shopId
                )
                
                // Cập nhật revenue record
                try await updateRevenueRecord(for: newOrder)
                
                // In hóa đơn nếu có kết nối máy in
                await printReceipt(for: newOrder)
                
                // Xóa giỏ hàng sau khi đặt hàng thành công
                clearOrder()
                let shortId = String(createdOrderId.suffix(6)).uppercased()
                source.showSuccess("Order created with ID#\(shortId)")
            }
        } catch {
            source.handleError(error)
            throw error
        }
    }
    
    func setOffSet(_ offSet: CGFloat) {
        dragOffset = offSet
    }
    
    private func updateIngredientUsage(for order: Order) async throws {
        var alerts: [IngredientAlert] = []
        
        try await source.environment.databaseService.runTransaction { transaction in
            // BƯỚC 1: Đọc tất cả ingredients cần thiết và tính toán số lượng
            var ingredientUpdates: [(ingredient: IngredientUsage, requiredAmount: Double)] = []
            
            for item in order.items {
                guard let menuItem = self.menuItems.first(where: { $0.id == item.menuItemId }) else {
                    print("⚠️ MenuItem not found: \(item.name)")
                    continue
                }
                
                for recipe in menuItem.recipe {
                    do {
                        // Đọc ingredient từ database
                        let ingredient = try self.source.environment.databaseService.getIngredientUsageInTransaction(
                            transaction,
                            userId: self.source.userId,
                            shopId: self.source.activatedShop!.id!,
                            ingredientId: recipe.ingredientId
                        )
                        
                        // Tính toán lượng nguyên liệu cần sử dụng
                        let requiredAmount = recipe.requiredAmount
                        guard let convertedAmount = requiredAmount.converted(to: ingredient.measurementPerUnit.unit) else {
                            print("⚠️ Cannot convert measurement units for: \(recipe.ingredientName)")
                            continue
                        }
                        
                        // Tính tổng lượng nguyên liệu cần cho đơn hàng
                        let totalRequired = convertedAmount.value * Double(item.quantity)
                        
                        // Kiểm tra số lượng tồn kho
                        let availableAmount = ingredient.totalMeasurement - ingredient.used
                        guard availableAmount >= totalRequired else {
                            throw AppError.database(.insufficientIngredient(name: ingredient.name))
                        }
                        
                        // Thêm vào danh sách cần update
                        if let existingIndex = ingredientUpdates.firstIndex(where: { $0.ingredient.id == ingredient.id }) {
                            // Cộng dồn số lượng nếu ingredient đã tồn tại
                            ingredientUpdates[existingIndex].requiredAmount += totalRequired
                        } else {
                            // Thêm mới nếu chưa có
                            ingredientUpdates.append((ingredient: ingredient, requiredAmount: totalRequired))
                        }
                    } catch {
                        print("🔥 Error reading ingredient \(recipe.ingredientName): \(error.localizedDescription)")
                        throw error
                    }
                }
            }
            
            // BƯỚC 2: Thực hiện tất cả các updates sau khi đã đọc xong
            for var update in ingredientUpdates {
                // Cập nhật số lượng đã sử dụng
                update.ingredient.used += update.requiredAmount
                update.ingredient.updatedAt = Date()
                
                // Kiểm tra và thêm cảnh báo nếu tồn kho thấp
                if update.ingredient.isLowStock {
                    alerts.append(IngredientAlert(ingredient: update.ingredient))
                }
                
                // Cập nhật ingredient trong transaction
                try self.source.environment.databaseService.updateIngredientUsageInTransaction(
                    transaction,
                    ingredientUsage: update.ingredient,
                    userId: self.source.userId,
                    shopId: self.source.activatedShop!.id!
                )
            }
            
            return nil
        }
        
        // Cập nhật danh sách cảnh báo
        await MainActor.run {
            self.ingredientAlerts = alerts
        }
    }
    
    private func updateRevenueRecord(for order: Order) async throws {
        guard let shopId = source.activatedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let orderHour = calendar.component(.hour, from: order.createdAt)
        let dayOfWeek = calendar.component(.weekday, from: order.createdAt) - 1 // 0 = Sunday
        
        // Tìm revenue record cho ngày hôm nay
        let existingRecord: RevenueRecord? = try await source.environment.databaseService.getRevenueRecord(
            userId: source.userId,
            shopId: shopId,
            with: { query in
                query.whereField("date", isEqualTo: today)
            }
        )
        
        if var record = existingRecord {
            // Cập nhật record hiện có
            record.revenue += order.totalAmount
            record.totalOrders += 1
            record.averageOrderValue = record.revenue / Double(record.totalOrders)
            
            // Cập nhật top selling items
            for item in order.items {
                if let menuItem = menuItems.first(where: { $0.id == item.menuItemId }) {
                    record.topSellingItems[menuItem.id!] = (record.topSellingItems[menuItem.id!] ?? 0) + item.quantity
                }
            }
            
            // Cập nhật peak hours
            record.peakHours[orderHour] = (record.peakHours[orderHour] ?? 0) + order.totalAmount
            
            // Cập nhật doanh thu theo ngày trong tuần
            record.dayOfWeekRevenue[dayOfWeek] = (record.dayOfWeekRevenue[dayOfWeek] ?? 0) + order.totalAmount
            
            // Cập nhật thông tin khách hàng
            if order.customer == nil {
                record.newCustomers += 1
            } else {
                record.returningCustomers += 1
            }
            record.totalCustomers = record.newCustomers + record.returningCustomers
            
            // Cập nhật phương thức thanh toán
            let paymentMethodKey = order.paymentMethod.rawValue
            record.paymentMethods[paymentMethodKey] = (record.paymentMethods[paymentMethodKey] ?? 0) + 1
            
            record.updatedAt = Date()
            
            // Lưu record đã cập nhật
            try await source.environment.databaseService.updateRevenueRecord(
                record,
                userId: source.userId,
                shopId: shopId,
                revenueRecordId: record.id ?? ""
            )
        } else {
            // Tạo record mới cho ngày hôm nay
            var topSellingItems: [String: Int] = [:]
            var peakHours: [Int: Double] = [:]
            var dayOfWeekRevenue: [Int: Double] = [:]
            var paymentMethods: [String: Int] = [:]
            
            // Khởi tạo dữ liệu từ order hiện tại
            for item in order.items {
                if let menuItem = menuItems.first(where: { $0.id == item.menuItemId }) {
                    topSellingItems[menuItem.id!] = item.quantity
                }
            }
            
            peakHours[orderHour] = order.totalAmount
            dayOfWeekRevenue[dayOfWeek] = order.totalAmount
            paymentMethods[order.paymentMethod.rawValue] = 1
            
            let newRecord = RevenueRecord(
                shopId: shopId,
                date: today,
                revenue: order.totalAmount,
                totalOrders: 1,
                averageOrderValue: order.totalAmount,
                topSellingItems: topSellingItems,
                peakHours: peakHours,
                dayOfWeekRevenue: dayOfWeekRevenue,
                newCustomers: order.customer == nil ? 1 : 0,
                returningCustomers: order.customer == nil ? 0 : 1,
                totalCustomers: 1,
                paymentMethods: paymentMethods,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Tạo record mới
            let _ = try await source.environment.databaseService.createRevenueRecord(
                newRecord,
                userId: source.userId,
                shopId: shopId
            )
        }
        
        // Cập nhật điểm tích lũy cho khách hàng
        if var customer = order.customer {
            let pointRate = source.activatedShop?.pointRate ?? 0.05 // Mặc định 5% nếu không có cấu hình
            let earnedPoints = order.totalAmount * pointRate
            customer.point += earnedPoints
            
            try await source.environment.databaseService.updateCustomer(
                customer,
                userId: source.userId,
                shopId: shopId,
                customerId: customer.id ?? ""
            )
        }
    }
    
    // MARK: - Search Methods
    func updateMenuSearchKey(_ newValue: String) {
        menuSearchKey = newValue
        isSearchingMenu = !newValue.isEmpty
    }
    
    func updateCustomerSearchKey(_ newValue: String) {
        customerSearchKey = newValue
        isSearchingCustomers = !newValue.isEmpty
    }
    
    func clearMenuSearch() {
        menuSearchKey = ""
        isSearchingMenu = false
    }
    
    func clearCustomerSearch() {
        customerSearchKey = ""
        isSearchingCustomers = false
    }
    
    // MARK: - Print Methods
    private func printReceipt(for order: Order) async {
        do {
            try await source.environment.printerService.printReceipt(for: order)
        } catch {
            // Nếu lỗi là do chưa kết nối máy in, hiển thị thông báo
            if let printerError = error as? AppError,
               case .printer(let _) = printerError {
                source.showInfo("Máy in chưa được kết nối nên không thể in hóa đơn")
            } else {
                // Các lỗi khác sẽ được xử lý bởi source.handleError
                source.handleError(error)
            }
        }
    }
}
