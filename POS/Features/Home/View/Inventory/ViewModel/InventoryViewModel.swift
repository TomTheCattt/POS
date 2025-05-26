import SwiftUI
import Combine

final class InventoryViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published private(set) var inventoryItems: [InventoryItem] = []
    @Published private(set) var filteredItems: [InventoryItem] = []
    @Published private(set) var lowStockItems: [InventoryItem] = []
    
    @Published var searchText: String = ""
    @Published var showLowStockOnly: Bool = false
    @Published var sortOrder: SortOrder = .name
    @Published var showAddItemSheet: Bool = false
    @Published var showEditItemSheet: Bool = false
    @Published var selectedItem: InventoryItem?
    
    // MARK: - Computed Properties
    private var sortedAndFilteredItems: [InventoryItem] {
        var items = inventoryItems
        
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if showLowStockOnly {
            items = items.filter { $0.isLowStock }
        }
        
        switch sortOrder {
        case .name:
            items.sort { $0.name < $1.name }
        case .quantity:
            items.sort { $0.quantity > $1.quantity }
        }
        
        return items
    }
    
    // MARK: - Initialization
    required init(environment: AppEnvironment) {
        super.init()
        setupBindings()
        Task {
            do {
                try await loadInventory()
            }
        }
    }
    
    private func setupBindings() {
        // Observe search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFilteredItems()
            }
            .store(in: &cancellables)
        
        // Observe filter changes
        Publishers.CombineLatest3($searchText, $showLowStockOnly, $sortOrder)
            .sink { [weak self] _ in
                self?.updateFilteredItems()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func updateFilteredItems() {
        filteredItems = sortedAndFilteredItems
    }
    
    private func loadInventory() async throws {
        isLoading = true
        
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        do {
            inventoryItems = try await environment.databaseService.getAllInventoryItems(userId: userId, shopId: shopId)
            
            updateFilteredItems()
        }
        
        isLoading = false
    }
    
    // MARK: - Public Methods
    func refresh() async throws {
        try await loadInventory()
    }
    
    func createItem(_ item: InventoryItem) async throws {
        isLoading = true
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        do {
            inventoryItems.append(item)
            let _ = try await environment.databaseService.createInventoryItem(item, userId: userId, shopId: shopId)
            updateFilteredItems()
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    func updateItem(_ item: InventoryItem) async throws {
        isLoading = true
        do {
            guard let userId = currentUser?.id else {
                throw AppError.auth(.userNotFound)
            }
            
            guard let shopId = selectedShop?.id else {
                throw AppError.shop(.notFound)
            }
            
            guard let itemId = selectedItem?.id else {
                throw AppError.inventory(.notFound)
            }
            if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
                inventoryItems[index] = item
            }
            let _ = try await environment.databaseService.updateInventoryItem(item, userId: userId, shopId: shopId, inventoryItemId: itemId)
            updateFilteredItems()
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    func deleteItem(_ item: InventoryItem) async throws {
        isLoading = true
        do {
            guard let userId = currentUser?.id else {
                throw AppError.auth(.userNotFound)
            }
            
            guard let shopId = selectedShop?.id else {
                throw AppError.shop(.notFound)
            }
            
            guard let itemId = selectedItem?.id else {
                throw AppError.inventory(.notFound)
            }
            
            inventoryItems.removeAll { $0.id == item.id }
            try await environment.databaseService.deleteInventoryItem(userId: userId, shopId: shopId, inventoryItemId: itemId)
            updateFilteredItems()
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
//    func adjustQuantity(for item: InventoryItem, by adjustment: Double) async throws {
//        isLoading = true
//        do {
//            //try await environment.inventoryService.adjustQuantity(itemId: item.id ?? "", adjustment: adjustment)
//            await loadInventory() // Reload to get updated quantities
//        } catch {
//            handleError(error)
//        }
//        isLoading = false
//    }
//    
//    func checkStock(itemId: String, requiredQuantity: Double) async throws -> Bool {
//        do {
//            //return try await environment.inventoryService.checkStock(itemId: itemId, requiredQuantity: requiredQuantity)
//        } catch {
//            handleError(error)
//            return false
//        }
//    }
}

// MARK: - Supporting Types
extension InventoryViewModel {
    enum SortOrder {
        case name
        case quantity
    }
}
