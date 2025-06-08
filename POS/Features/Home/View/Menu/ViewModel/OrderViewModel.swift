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
    
    // MARK: - Dependencies
    private let source: SourceModel
    
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
            (searchKey.isEmpty || $0.name.localizedCaseInsensitiveContains(searchKey))
        }
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBinding()
    }
    
    private func setupBinding() {
        source.menuItemsPublisher
            .sink { [weak self] menuItems in
                guard let self = self,
                      let menuItems = menuItems else { return }
                self.menuItems = menuItems
                self.updateCategories(from: menuItems)
            }
            .store(in: &source.cancellables)
    }
    
    private func updateCategories(from items: [MenuItem]) {
        var uniqueCategories = Set(items.map { $0.category })
        uniqueCategories.insert("All")
        categories = Array(uniqueCategories).sorted()
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
        objectWillChange.send()
    }
    
    func createOrder() async throws {
        let discount = 0.0
        
        guard let userId = source.currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = source.activatedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        // Tính toán tổng tiền
        let subTotal = selectedItems.reduce(0) { result, item in
            result + (item.price * Double(item.quantity))
        }
        
        let total = subTotal * (1 - discount)
        
        let newOrder = Order(
            items: selectedItems,
            totalAmount: total,
            paymentMethod: paymentMethod,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            // Kiểm tra và cập nhật số lượng nguyên liệu trước
            try await updateIngredientUsage(for: newOrder)
            
            // Sau khi kiểm tra nguyên liệu thành công, tạo đơn hàng mới
            let createdOrderId = try await source.environment.databaseService.createOrder(
                newOrder,
                userId: userId,
                shopId: shopId
            )
            
            // Xóa giỏ hàng sau khi đặt hàng thành công
            clearOrder()
            let shortId = String(createdOrderId.suffix(6)).uppercased()
            source.showSuccess("Order created with ID#\(shortId)")
        } catch {
            source.handleError(error)
            throw error
        }
    }
    
    private func updateIngredientUsage(for order: Order) async throws {
        var alerts: [IngredientAlert] = []
        
        try await source.environment.databaseService.runTransaction { transaction in
            // BƯỚC 1: Đọc tất cả ingredients cần thiết và tính toán số lượng
            var ingredientUpdates: [(ingredient: IngredientUsage, requiredAmount: Double)] = []
            
            for item in order.items {
                guard let menuItem = self.menuItems.first(where: { $0.name == item.name }) else {
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
} 
