//
//  MenuViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import Combine

final class MenuViewModel: BaseViewModel {
    var isLoading: Bool = false
    
    var errorMessage: String?
    
    var showError: Bool = false
    
    // MARK: - Dependencies
    let environment: AppEnvironment
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published private(set) var searchKey: String = ""
    @Published private(set) var paymentMethod: PaymentMethod = .cash
    @Published private(set) var selectedItems: [OrderItem] = []
    @Published private(set) var selectedCategory: String = "All"
    @Published private(set) var displayName: String = "Unknown User"
    @Published private(set) var menuItems: [MenuItem] = []
    
    // MARK: - Constants
    private(set) var categories = ["All", "Coffee", "Tea", "Pastries", "Sandwiches", "Drinks"]
    
    // MARK: - Computed Properties
    var filteredMenuItems: [MenuItem] {
        menuItems.filter {
            (selectedCategory == "All" || $0.category == selectedCategory) &&
            (searchKey.isEmpty || $0.name.localizedCaseInsensitiveContains(searchKey))
        }
    }
    
    var totalPrice: String {
        let total = selectedItems.reduce(0.0) { result, item in
            let menuItem = menuItems.first(where: { $0.id == item.menuItemId })
            let itemPrice = menuItem?.price ?? 0
            return result + Double(itemPrice) * Double(item.quantity)
        }
        return "$\(String(format: "%.2f", total))"
    }
    
    // MARK: - Initialization
    init(environment: AppEnvironment) {
        self.environment = environment
        setupBindings()
        loadMenuItems()
    }
    
    private func setupBindings() {
        // Observe user changes
        authService.currentUserPublisher
            .sink { [weak self] user in
                self?.displayName = user?.displayName ?? "Unknown User"
            }
            .store(in: &cancellables)
    }
    
    private func loadMenuItems() {
        // TODO: Load menu items from database service
        // For now using mock data
        self.menuItems = [
            MenuItem(id: "1", name: "Espresso", price: 3.0, category: "Coffee",
                     ingredients: [IngredientUsage(inventoryItemID: "beans", quantity: 18, unit: .gram)],
                     isAvailable: true),
            // ... other menu items ...
        ]
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
            $0.menuItemId == item.id &&
            $0.temprature == temperature &&
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
                menuItemId: item.id,
                quantity: 1,
                temprature: temperature,
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
    
    func createOrder() {
        Task { [weak self] in
            guard let self = self else { return }

            let total = self.selectedItems.reduce(0.0) { result, item in
                let menuItem = self.menuItems.first(where: { $0.id == item.menuItemId })
                let price = menuItem?.price ?? 0
                return result + price * Double(item.quantity)
            }

            let discount = 0.0
            let newOrder = Order(
                id: UUID().uuidString,
                items: selectedItems,
                createdAt: Date(),
                totalAmount: total,
                discount: discount,
                paymentMethod: paymentMethod
            )

            do {
                _ = try await environment.orderService.createOrder(order: newOrder)
                self.clearOrder()
            } catch {
                print("Error creating order: \(error)")
                self.handleError(error)
            }
        }
    }
    
    func getMenuItem(by id: String) -> MenuItem? {
        return menuItems.first(where: { $0.id == id })
    }
}

