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
        //Bổ sung tính discount
        let total = selectedItems.reduce(0) { result, item in
            result + (item.price * Double(item.quantity))
        }
        return "$\(String(format: "%.2f", total))"
    }
    
    // MARK: - Initialization
    init(environment: AppEnvironment) {
        self.environment = environment
        setupBindings()
    }
    
    private func setupBindings() {
        authService.currentUserPublisher
            .sink { [weak self] user in
                self?.displayName = user?.displayName ?? "Unknown User"
            }
            .store(in: &cancellables)
        
        menuService.menuItemsPublisher
            .sink { [weak self] menuItems in
                self?.menuItems = menuItems ?? []
            }
            .store(in: &cancellables)
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
    
    func createOrder() {
        let discount = 0.0
        Task { [weak self] in
            guard let self = self else { return }

            let subTotal = self.selectedItems.reduce(0) { _, item in
                return item.price * Double(item.quantity)
            }
            
            let total = subTotal * discount

            let discount = 0.0
            let newOrder = Order(items: selectedItems, totalAmount: total, paymentMethod: paymentMethod, createdAt: Date(), updatedAt: Date())

            do {
                _ = try await environment.orderService.createOrder(newOrder)
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

