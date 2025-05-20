import SwiftUI
import Combine

final class InventoryViewModel: BaseViewModel {
    // MARK: - BaseViewModel Properties
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    
    // MARK: - Dependencies
    let environment: AppEnvironment
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published private(set) var inventoryItems: [InventoryItem] = []
    @Published private(set) var filteredItems: [InventoryItem] = []
    @Published private(set) var lowStockItems: [InventoryItem] = []
    @Published private(set) var inventoryReport: InventoryReport?
    
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
        self.environment = environment
        setupBindings()
        Task {
            await loadInventory()
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
    
    @MainActor
    private func loadInventory() async {
        isLoading = true
        
        do {
            // Load inventory items
            inventoryItems = try await inventoryService.fetchInventoryItems()
            
            // Load low stock items
            lowStockItems = try await inventoryService.getLowStockItems(threshold: 10)
            
            // Generate inventory report
            inventoryReport = try await inventoryService.generateInventoryReport()
            
            updateFilteredItems()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Public Methods
    func refresh() async {
        await loadInventory()
    }
    
    func createItem(_ item: InventoryItem) async throws {
        isLoading = true
        do {
            try await inventoryService.createInventoryItem(item)
            inventoryItems.append(item)
            updateFilteredItems()
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    func updateItem(_ item: InventoryItem) async throws {
        isLoading = true
        do {
            try await inventoryService.updateInventoryItem(item)
            if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
                inventoryItems[index] = item
            }
            updateFilteredItems()
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    func deleteItem(_ item: InventoryItem) async throws {
        isLoading = true
        do {
            try await inventoryService.deleteInventoryItem(item)
            inventoryItems.removeAll { $0.id == item.id }
            updateFilteredItems()
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    func adjustQuantity(for item: InventoryItem, by adjustment: Double) async throws {
        isLoading = true
        do {
            try await inventoryService.adjustQuantity(itemId: item.id ?? "", adjustment: adjustment)
            await loadInventory() // Reload to get updated quantities
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    func checkStock(itemId: String, requiredQuantity: Double) async throws -> Bool {
        do {
            return try await inventoryService.checkStock(itemId: itemId, requiredQuantity: requiredQuantity)
        } catch {
            handleError(error)
            return false
        }
    }
}

// MARK: - Supporting Types
extension InventoryViewModel {
    enum SortOrder {
        case name
        case quantity
    }
}
