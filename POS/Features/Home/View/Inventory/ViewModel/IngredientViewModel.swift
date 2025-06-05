import SwiftUI
import Combine

@MainActor
final class IngredientViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var searchKey: String = ""
    @Published private(set) var selectedCategory: String = "All"
    @Published private(set) var categories: [String] = ["All"]
    @Published private(set) var isLoading: Bool = false
    
    @Published var showLowStockOnly: Bool = false
    @Published var sortOrder: SortOrder = .name
    @Published var showAddItemSheet: Bool = false
    @Published var showEditItemSheet: Bool = false
    @Published var selectedItem: IngredientUsage?
    @Published var selectedStockStatus: IngredientUsage.StockStatus?
    
    var ingredients: [IngredientUsage] = []
    
    // MARK: - Dependencies
    private let source: SourceModel
    
    // MARK: - Computed Properties
    var filteredAndSortedItems: [IngredientUsage] {
        
        guard let ingredients = source.ingredients else { return [] }
        
        var items = ingredients
        
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
        source.activatedShopPublisher
            .sink { [weak self] shop in
                guard let self = self,
                      let shopId = shop?.id else { return }
                self.source.setupIngredientsListener(shopId: shopId)
            }
            .store(in: &source.cancellables)
        source.ingredientsPublisher
            .sink { [weak self] ingredients in
                guard let self = self, let ingredients = ingredients else { return }
                self.ingredients = ingredients
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
            .store(in: &source.cancellables)
            
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
    
    func updateSelectedStockStatus(_ status: IngredientUsage.StockStatus?) {
        selectedStockStatus = status
    }
    
    // MARK: - Inventory Item Management
    func createIngredientUsage(_ item: IngredientUsage) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id else { return }
            
            _ = try await source.environment.databaseService.createIngredientUsage(
                item,
                userId: userId,
                shopId: shopId
            )
        } catch {
            source.handleError(error, action: "thêm sản phẩm mới")
        }
    }
    
    func updateIngredientUsage(_ item: IngredientUsage) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let itemId = item.id else { return }
            
            try await source.environment.databaseService.updateIngredientUsage(
                item,
                userId: userId,
                shopId: shopId,
                ingredientsUsageId: itemId
            )
        } catch {
            source.handleError(error, action: "cập nhật sản phẩm")
        }
    }
    
    func deleteIngredientUsage(_ item: IngredientUsage) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let itemId = item.id else { return }
            
            try await source.environment.databaseService.deleteIngredientUsage(
                userId: userId,
                shopId: shopId,
                ingredientsUsageId: itemId
            )
        } catch {
            source.handleError(error, action: "xóa sản phẩm")
        }
    }
    
    func importIngredientUsages(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let items = try parseIngredientUsagesFromCSV(data)
            
            for item in items {
                await createIngredientUsage(item)
            }
        } catch {
            source.handleError(error, action: "nhập danh sách sản phẩm từ file")
        }
    }
    
    private func parseIngredientUsagesFromCSV(_ data: Data) throws -> [IngredientUsage] {
        // Implement CSV parsing logic here
        // Return array of IngredientUsage
        return []
    }
    
    func adjustQuantity(for item: IngredientUsage, by adjustment: Double) async throws {
        var updatedItem = item
        updatedItem.quantity += adjustment
        updatedItem.updatedAt = Date()
        await updateIngredientUsage(updatedItem)
    }
    
    func checkLowStock(_ item: IngredientUsage) -> Bool {
        return item.quantity <= item.minQuantity
    }
    
    func formatQuantity(_ quantity: Double) -> String {
        return String(format: "%.2f", quantity)
    }
}

// MARK: - Supporting Types
extension IngredientViewModel {
    enum SortOrder {
        case name
        case quantity
        case lastUpdated
    }
}
