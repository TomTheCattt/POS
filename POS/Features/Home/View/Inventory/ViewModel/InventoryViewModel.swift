import SwiftUI
import Combine

@MainActor
final class InventoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var searchKey: String = ""
    @Published private(set) var selectedCategory: String = "All"
    @Published private(set) var inventoryItems: [InventoryItem] = []
    @Published private(set) var categories: [String] = ["All"]
    @Published private(set) var isLoading: Bool = false
    
    @Published var showLowStockOnly: Bool = false
    @Published var sortOrder: SortOrder = .name
    @Published var showAddItemSheet: Bool = false
    @Published var showEditItemSheet: Bool = false
    @Published var selectedItem: InventoryItem?
    @Published var selectedStockStatus: InventoryItem.StockStatus?
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredAndSortedItems: [InventoryItem] {
        var items = inventoryItems
        
        // Lọc theo từ khóa tìm kiếm
        if !searchKey.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchKey)
            }
        }
        
        // Lọc theo trạng thái kho
        if let stockStatus = selectedStockStatus {
            items = items.filter { $0.stockStatus == stockStatus }
        }
        
        // Lọc các mặt hàng sắp hết
        if showLowStockOnly {
            items = items.filter { $0.isLowStock }
        }
        
        // Sắp xếp theo tiêu chí đã chọn
        switch sortOrder {
        case .name:
            items.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .quantity:
            items.sort { $0.quantity > $1.quantity }
        case .lastUpdated:
            items.sort { $0.updatedAt > $1.updatedAt }
        }
        
        return items
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        // Lắng nghe thay đổi của inventory từ SourceModel
        source.inventoryPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                guard let self = self,
                      let items = items else { return }
                self.inventoryItems = items
            }
            .store(in: &source.cancellables)
        
        // Lắng nghe thay đổi từ showLowStockOnly
        $showLowStockOnly
            .sink { _ in
                // Không cần làm gì vì computed property sẽ tự cập nhật
            }
            .store(in: &source.cancellables)
        
        // Lắng nghe thay đổi từ sortOrder
        $sortOrder
            .sink { _ in
                // Không cần làm gì vì computed property sẽ tự cập nhật
            }
            .store(in: &cancellables)
            
        // Lắng nghe trạng thái loading từ SourceModel
        source.loadingPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] loading, _ in
                self?.isLoading = loading
            }
            .store(in: &source.cancellables)
    }
    
    // MARK: - Public Methods
    func updateSearchKey(_ newValue: String) {
        searchKey = newValue
    }
    
    func updateSelectedCategory(_ category: String) {
        selectedCategory = category
    }
    
    func updateSelectedStockStatus(_ status: InventoryItem.StockStatus?) {
        selectedStockStatus = status
    }
    
    // MARK: - Inventory Item Management
    func createInventoryItem(_ item: InventoryItem) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.selectedShop?.id else { return }
            
            _ = try await source.environment.databaseService.createInventoryItem(
                item,
                userId: userId,
                shopId: shopId
            )
        } catch {
            source.handleError(error, action: "thêm sản phẩm mới")
        }
    }
    
    func updateInventoryItem(_ item: InventoryItem) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.selectedShop?.id,
                  let itemId = item.id else { return }
            
            try await source.environment.databaseService.updateInventoryItem(
                item,
                userId: userId,
                shopId: shopId,
                inventoryItemId: itemId
            )
        } catch {
            source.handleError(error, action: "cập nhật sản phẩm")
        }
    }
    
    func deleteInventoryItem(_ item: InventoryItem) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.selectedShop?.id,
                  let itemId = item.id else { return }
            
            try await source.environment.databaseService.deleteInventoryItem(
                userId: userId,
                shopId: shopId,
                inventoryItemId: itemId
            )
        } catch {
            source.handleError(error, action: "xóa sản phẩm")
        }
    }
    
    func importInventoryItems(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let items = try parseInventoryItemsFromCSV(data)
            
            for item in items {
                await createInventoryItem(item)
            }
        } catch {
            source.handleError(error, action: "nhập danh sách sản phẩm từ file")
        }
    }
    
    private func parseInventoryItemsFromCSV(_ data: Data) throws -> [InventoryItem] {
        // Implement CSV parsing logic here
        // Return array of InventoryItem
        return []
    }
    
    func adjustQuantity(for item: InventoryItem, by adjustment: Double) async throws {
        var updatedItem = item
        updatedItem.quantity += adjustment
        updatedItem.updatedAt = Date()
        await updateInventoryItem(updatedItem)
    }
    
    func checkLowStock(_ item: InventoryItem) -> Bool {
        return item.quantity <= item.minQuantity
    }
    
    func formatQuantity(_ quantity: Double) -> String {
        return String(format: "%.2f", quantity)
    }
}

// MARK: - Supporting Types
extension InventoryViewModel {
    enum SortOrder {
        case name
        case quantity
        case lastUpdated
    }
}
