import SwiftUI
import Combine

final class InventoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    private var inventoryItems: [InventoryItem] = []
    private var filteredItems: [InventoryItem] = []
    
    @Published var searchText: String = ""
    @Published var showLowStockOnly: Bool = false
    @Published var sortOrder: SortOrder = .name
    @Published var showAddItemSheet: Bool = false
    @Published var showEditItemSheet: Bool = false
    @Published var selectedItem: InventoryItem?
    
    private var source: SourceModel
    
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
    init(source: SourceModel) {
        self.source = source
        setupBindings()
        Task {
            do {
                try await loadInventory()
            }
        }
    }
    
    private func setupBindings() {
        // Observe search text changes
//        $searchText
//            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.updateFilteredItems()
//            }
//            .store(in: &cancellables)
//        
//        // Observe filter changes
//        Publishers.CombineLatest3($searchText, $showLowStockOnly, $sortOrder)
//            .sink { [weak self] _ in
//                self?.updateFilteredItems()
//            }
//            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func updateFilteredItems() {
        filteredItems = sortedAndFilteredItems
    }
    
    private func loadInventory() async throws {
        
        guard let userId = await source.currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = await source.selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        do {
            inventoryItems = try await source.environment.databaseService.getAllInventoryItems(userId: userId, shopId: shopId)
            
            updateFilteredItems()
        }
    }
    
    // MARK: - Public Methods
    func refresh() async throws {
        try await loadInventory()
    }
    
    func createItem(_ item: InventoryItem) async throws {
        guard let userId = await source.currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = await source.selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        do {
            inventoryItems.append(item)
            let _ = try await source.environment.databaseService.createInventoryItem(item, userId: userId, shopId: shopId)
            updateFilteredItems()
        } catch {
            await source.handleError(error)
        }
    }
    
    func updateItem(_ item: InventoryItem) async throws {
        do {
            guard let userId = await source.currentUser?.id else {
                throw AppError.auth(.userNotFound)
            }
            
            guard let shopId = await source.selectedShop?.id else {
                throw AppError.shop(.notFound)
            }
            
            guard let itemId = selectedItem?.id else {
                throw AppError.inventory(.notFound)
            }
            if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
                inventoryItems[index] = item
            }
            let _ = try await source.environment.databaseService.updateInventoryItem(item, userId: userId, shopId: shopId, inventoryItemId: itemId)
            updateFilteredItems()
        } catch {
            await source.handleError(error)
        }
    }
    
    func deleteItem(_ item: InventoryItem) async throws {
        do {
            guard let userId = await source.currentUser?.id else {
                throw AppError.auth(.userNotFound)
            }
            
            guard let shopId = await source.selectedShop?.id else {
                throw AppError.shop(.notFound)
            }
            
            guard let itemId = selectedItem?.id else {
                throw AppError.inventory(.notFound)
            }
            
            inventoryItems.removeAll { $0.id == item.id }
            try await source.environment.databaseService.deleteInventoryItem(userId: userId, shopId: shopId, inventoryItemId: itemId)
            updateFilteredItems()
        } catch {
            await source.handleError(error)
        }
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
//    func checkStock(itemId: String, privateQuantity: Double) async throws -> Bool {
//        do {
//            //return try await environment.inventoryService.checkStock(itemId: itemId, privateQuantity: privateQuantity)
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
