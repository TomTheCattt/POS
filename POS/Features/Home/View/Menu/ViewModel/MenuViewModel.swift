//
//  MenuViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import Combine

@MainActor
final class MenuViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var searchKey: String = ""
    @Published private(set) var paymentMethod: PaymentMethod = .cash
    @Published private(set) var selectedItems: [OrderItem] = []
    @Published private(set) var selectedCategory: String = "All"
    @Published private(set) var displayName: String = "Unknown User"
    @Published private(set) var menuItems: [MenuItem] = []
    @Published private(set) var categories: [String] = ["All"]
    
    // MARK: - Dependencies
    private let source: SourceModel
    
    // MARK: - Computed Properties
    var filteredMenuItems: [MenuItem] {
        menuItems.filter {
            (selectedCategory == "All" || $0.category == selectedCategory) &&
            (searchKey.isEmpty || $0.name.localizedCaseInsensitiveContains(searchKey))
        }
    }
    
    var totalPrice: String {
        let total = selectedItems.reduce(0) { result, item in
            result + (item.price * Double(item.quantity))
        }
        return "$\(String(format: "%.2f", total))"
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        // Lắng nghe thay đổi của menu từ SourceModel
        source.menuPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] menuItems in
                guard let self = self,
                      let items = menuItems else { return }
                self.menuItems = items
                self.updateCategories(from: items)
            }
            .store(in: &source.cancellables)
        
        // Lắng nghe thay đổi của user từ SourceModel
        source.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.displayName = user?.displayName ?? "Unknown User"
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
    
    func updatePaymentMethod(_ method: PaymentMethod) {
        paymentMethod = method
    }
    
    func updateSelectedCategory(_ category: String) {
        selectedCategory = category
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
        
        guard let shopId = source.selectedShop?.id else {
            throw AppError.shop(.notFound)
        }

        let subTotal = selectedItems.reduce(0) { _, item in
            return item.price * Double(item.quantity)
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
            _ = try await source.environment.databaseService.createOrder(newOrder, userId: userId, shopId: shopId)
            clearOrder()
        } catch {
            source.handleError(error)
        }
    }
    
    func getMenuItem(by id: String) -> MenuItem? {
        return menuItems.first(where: { $0.id == id })
    }
    
    // MARK: - Menu Item Management
    func createMenuItem(_ item: MenuItem, imageData: Data?) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.selectedShop?.id else { return }
            
            var menuItem = item
            
            // Upload ảnh nếu có
            if let imageData = imageData {
                let imageURL = try await source.environment.storageService.uploadImage(
                    imageData,
                    path: "menu/\(shopId)/\(UUID().uuidString)"
                )
                menuItem = MenuItem(
                    id: item.id,
                    name: item.name,
                    price: item.price,
                    category: item.category,
                    ingredients: item.ingredients,
                    isAvailable: item.isAvailable,
                    imageURL: imageURL,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt
                )
            }
            
            _ = try await source.environment.databaseService.createMenuItem(
                menuItem,
                userId: userId,
                shopId: shopId
            )
        } catch {
            source.handleError(error, action: "thêm món mới")
        }
    }
    
    func updateMenuItem(_ item: MenuItem, imageData: Data?) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.selectedShop?.id,
                  let itemId = item.id else { return }
            
            var menuItem = item
            
            // Upload ảnh mới nếu có
            if let imageData = imageData {
                let imageURL = try await source.environment.storageService.uploadImage(
                    imageData,
                    path: "menu/\(shopId)/\(UUID().uuidString)"
                )
                menuItem = MenuItem(
                    id: item.id,
                    name: item.name,
                    price: item.price,
                    category: item.category,
                    ingredients: item.ingredients,
                    isAvailable: item.isAvailable,
                    imageURL: imageURL,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt
                )
            }
            
            _ = try await source.environment.databaseService.updateMenuItem(
                menuItem,
                userId: userId,
                shopId: shopId,
                menuItemId: itemId
            )
        } catch {
            source.handleError(error, action: "cập nhật món")
        }
    }
    
    func deleteMenuItem(_ item: MenuItem) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.selectedShop?.id,
                  let itemId = item.id else { return }
            
            // Xóa ảnh nếu có
            if let imageURL = item.imageURL {
                try await source.environment.storageService.deleteImage(at: imageURL)
            }
            
            try await source.environment.databaseService.deleteMenuItem(
                userId: userId,
                shopId: shopId,
                menuItemId: itemId
            )
        } catch {
            source.handleError(error, action: "xóa món")
        }
    }
    
    func importMenuItems(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let items = try parseMenuItemsFromCSV(data)
            
            for item in items {
                await createMenuItem(item, imageData: nil)
            }
        } catch {
            source.handleError(error, action: "nhập danh sách món từ file")
        }
    }
    
    private func parseMenuItemsFromCSV(_ data: Data) throws -> [MenuItem] {
        // Implement CSV parsing logic here
        // Return array of MenuItem
        return []
    }
    
    func getInventoryItem(by id: String) async throws -> InventoryItem? {
        guard let userId = source.currentUser?.id, let selectedShopId = source.selectedShop?.id else {
            return nil
        }
        return try await source.environment.databaseService.getInventoryItem(userId: userId, shopId: selectedShopId, inventoryItemId: id)
    }
}

