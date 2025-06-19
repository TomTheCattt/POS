import SwiftUI
import Combine

// MARK: - Ingredient Validation Errors
enum IngredientValidationError: LocalizedError {
    case invalidName(String)
    case invalidQuantity(String)
    case invalidCostPrice(String)
    case invalidMinQuantity(String)
    case invalidMeasurement(String)
    case missingRequiredFields(String)
    case duplicateIngredient(String)
    case exceedMaxIngredientLimit(String)
    case invalidStockOperation(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName(let message): return "Lỗi tên nguyên liệu: \(message)"
        case .invalidQuantity(let message): return "Lỗi số lượng: \(message)"
        case .invalidCostPrice(let message): return "Lỗi giá vốn: \(message)"
        case .invalidMinQuantity(let message): return "Lỗi số lượng tối thiểu: \(message)"
        case .invalidMeasurement(let message): return "Lỗi đơn vị đo: \(message)"
        case .missingRequiredFields(let message): return "Thiếu thông tin: \(message)"
        case .duplicateIngredient(let message): return "Trùng lặp: \(message)"
        case .exceedMaxIngredientLimit(let message): return "Vượt giới hạn: \(message)"
        case .invalidStockOperation(let message): return "Lỗi thao tác kho: \(message)"
        }
    }
}

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
    
    // MARK: - Form States
    @Published var name: String = ""
    @Published var quantity: String = ""
    @Published var measurementUnit: MeasurementUnit = .gram
    @Published var costPrice: String = ""
    @Published var minQuantity: String = "1"
    
    // MARK: - Validation State
    @Published private(set) var validationErrors: [IngredientValidationError] = []
    
    var ingredients: [IngredientUsage] = []
    
    // MARK: - Constants
    private let maxIngredientPerShop = 1000
    private let maxNameLength = 100
    private let minNameLength = 2
    private let maxQuantity: Double = 1000000 // 1 triệu
//    private let minQuantity: Double = 0
    private let maxCostPrice: Double = 10000000 // 10 triệu
    private let minCostPrice: Double = 0
    private let maxMinQuantity: Double = 10000
    private let minMinQuantity: Double = 0.1
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        validationErrors.isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= minNameLength &&
        name.trimmingCharacters(in: .whitespacesAndNewlines).count <= maxNameLength &&
        (Double(quantity) ?? 0) >= Double(minQuantity) ?? 0 &&
        (Double(quantity) ?? 0) <= maxQuantity &&
        (Double(costPrice) ?? 0) >= minCostPrice &&
        (Double(costPrice) ?? 0) <= maxCostPrice &&
        (Double(minQuantity) ?? 0) >= minMinQuantity &&
        (Double(minQuantity) ?? 0) <= maxMinQuantity &&
        (Double(minQuantity) ?? 0) <= (Double(quantity) ?? 0)
    }
    
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
        source.ingredientsPublisher
            .sink { [weak self] ingredients in
                guard let self = self, let ingredients = ingredients else { return }
                self.ingredients = ingredients
            }
            .store(in: &cancellables)
        
        // Lắng nghe thay đổi từ showLowStockOnly
        $showLowStockOnly
            .sink { _ in
                // Không cần làm gì vì computed property sẽ tự cập nhật
            }
            .store(in: &cancellables)
        
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
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    private func validateIngredient() throws {
        validationErrors.removeAll()
        
        // Validate name
        try validateName()
        
        // Validate quantity
        try validateQuantity()
        
        // Validate cost price
        try validateCostPrice()
        
        // Validate min quantity
        try validateMinQuantity()
        
        // Validate measurement
        try validateMeasurement()
        
        // Validate max ingredient limit
        try validateMaxIngredientLimit()
        
        // Validate duplicate ingredient
        try validateDuplicateIngredient()
        
        if !validationErrors.isEmpty {
            throw validationErrors.first!
        }
    }
    
    private func validateName() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationErrors.append(.invalidName("Tên nguyên liệu không được để trống"))
        }
        
        if trimmedName.count < minNameLength {
            validationErrors.append(.invalidName("Tên nguyên liệu phải có ít nhất \(minNameLength) ký tự"))
        }
        
        if trimmedName.count > maxNameLength {
            validationErrors.append(.invalidName("Tên nguyên liệu không được vượt quá \(maxNameLength) ký tự"))
        }
        
        // Check for special characters (allow Vietnamese characters)
        if trimmedName.matches(pattern: "^[^a-zA-Z0-9\\s\\u00C0-\\u1EF9]+$") {
            validationErrors.append(.invalidName("Tên nguyên liệu chứa ký tự không hợp lệ"))
        }
        
        // Check for numbers only
        if trimmedName.matches(pattern: "^[0-9]+$") {
            validationErrors.append(.invalidName("Tên nguyên liệu không được chỉ chứa số"))
        }
    }
    
    private func validateQuantity() throws {
        guard let quantityValue = Double(quantity) else {
            validationErrors.append(.invalidQuantity("Số lượng không hợp lệ"))
            return
        }
        
        if quantityValue < Double(minQuantity) ?? 0 {
            validationErrors.append(.invalidQuantity("Số lượng không được âm"))
        }
        
        if quantityValue > maxQuantity {
            validationErrors.append(.invalidQuantity("Số lượng không được vượt quá \(formatNumber(maxQuantity))"))
        }
    }
    
    private func validateCostPrice() throws {
        guard let costPriceValue = Double(costPrice) else {
            validationErrors.append(.invalidCostPrice("Giá vốn không hợp lệ"))
            return
        }
        
        if costPriceValue < minCostPrice {
            validationErrors.append(.invalidCostPrice("Giá vốn không được âm"))
        }
        
        if costPriceValue > maxCostPrice {
            validationErrors.append(.invalidCostPrice("Giá vốn không được vượt quá \(formatCurrency(maxCostPrice))"))
        }
    }
    
    private func validateMinQuantity() throws {
        guard let minQuantityValue = Double(minQuantity) else {
            validationErrors.append(.invalidMinQuantity("Số lượng tối thiểu không hợp lệ"))
            return
        }
        
        if minQuantityValue < minMinQuantity {
            validationErrors.append(.invalidMinQuantity("Số lượng tối thiểu phải lớn hơn \(minMinQuantity)"))
        }
        
        if minQuantityValue > maxMinQuantity {
            validationErrors.append(.invalidMinQuantity("Số lượng tối thiểu không được vượt quá \(formatNumber(maxMinQuantity))"))
        }
        
        // Check if min quantity is greater than current quantity
        if let quantityValue = Double(quantity), minQuantityValue > quantityValue {
            validationErrors.append(.invalidMinQuantity("Số lượng tối thiểu không được lớn hơn số lượng hiện tại"))
        }
    }
    
    private func validateMeasurement() throws {
        // Validate measurement unit is valid
        guard MeasurementUnit.allCases.contains(measurementUnit) else {
            validationErrors.append(.invalidMeasurement("Đơn vị đo không hợp lệ"))
            return
        }
    }
    
    private func validateMaxIngredientLimit() throws {
        if ingredients.count >= maxIngredientPerShop {
            validationErrors.append(.exceedMaxIngredientLimit("Đã đạt giới hạn tối đa \(maxIngredientPerShop) nguyên liệu"))
        }
    }
    
    private func validateDuplicateIngredient() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingIngredient = ingredients.first { ingredient in
            ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedName.lowercased() &&
            ingredient.id != selectedItem?.id
        }
        
        if existingIngredient != nil {
            validationErrors.append(.duplicateIngredient("Đã có nguyên liệu tên '\(trimmedName)'"))
        }
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
    
    // MARK: - Form Management
    func resetForm() {
        name = ""
        quantity = ""
        measurementUnit = .gram
        costPrice = ""
        minQuantity = "1"
        validationErrors.removeAll()
    }
    
    func loadIngredientData(_ ingredient: IngredientUsage) {
        selectedItem = ingredient
        name = ingredient.name
        quantity = String(format: "%.2f", ingredient.quantity)
        measurementUnit = ingredient.measurementPerUnit.unit
        costPrice = String(format: "%.0f", ingredient.costPrice)
        minQuantity = String(format: "%.2f", ingredient.minQuantity)
    }
    
    // MARK: - Inventory Item Management
    func createIngredientUsage(_ item: IngredientUsage) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate before creating
            try validateIngredient()
            
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id else {
                throw IngredientValidationError.missingRequiredFields("Thông tin người dùng hoặc cửa hàng không hợp lệ")
            }
            
            _ = try await source.environment.databaseService.createIngredientUsage(
                item,
                userId: userId,
                shopId: shopId
            )
            
            // Clear form after successful creation
            resetForm()
            
        } catch {
            source.handleError(error, action: "thêm nguyên liệu mới")
            throw error
        }
    }
    
    func updateIngredientUsage(_ item: IngredientUsage) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate before updating
            try validateIngredient()
            
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let itemId = item.id else {
                throw IngredientValidationError.missingRequiredFields("Thông tin nguyên liệu không hợp lệ")
            }
            
            try await source.environment.databaseService.updateIngredientUsage(
                item,
                userId: userId,
                shopId: shopId,
                ingredientsUsageId: itemId
            )
            
            // Clear form after successful update
            resetForm()
            
        } catch {
            source.handleError(error, action: "cập nhật nguyên liệu")
            throw error
        }
    }
    
    func deleteIngredientUsage(_ item: IngredientUsage) async throws {
        guard let itemId = item.id else {
            throw IngredientValidationError.missingRequiredFields("ID nguyên liệu không hợp lệ")
        }
        
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id else {
                throw IngredientValidationError.missingRequiredFields("Thông tin người dùng hoặc cửa hàng không hợp lệ")
            }
            
            try await source.environment.databaseService.deleteIngredientUsage(
                userId: userId,
                shopId: shopId,
                ingredientsUsageId: itemId
            )
        } catch {
            source.handleError(error, action: "xóa nguyên liệu")
            throw error
        }
    }
    
    func importIngredientUsages(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let items = try parseIngredientUsagesFromCSV(data)
            
            for item in items {
                try await createIngredientUsage(item)
            }
        } catch {
            source.handleError(error, action: "nhập danh sách nguyên liệu từ file")
        }
    }
    
    private func parseIngredientUsagesFromCSV(_ data: Data) throws -> [IngredientUsage] {
        // Implement CSV parsing logic here
        // Return array of IngredientUsage
        return []
    }
    
    func adjustQuantity(for item: IngredientUsage, by adjustment: Double) async throws {
        // Validate adjustment
        if adjustment < 0 && abs(adjustment) > item.quantity {
            throw IngredientValidationError.invalidStockOperation("Không thể giảm số lượng vượt quá số lượng hiện tại")
        }
        
        if adjustment > maxQuantity {
            throw IngredientValidationError.invalidStockOperation("Số lượng điều chỉnh quá lớn")
        }
        
        var updatedItem = item
        updatedItem.quantity = max(0, item.quantity + adjustment)
        updatedItem.updatedAt = Date()
        try await updateIngredientUsage(updatedItem)
    }
    
    func checkLowStock(_ item: IngredientUsage) -> Bool {
        return item.isLowStock
    }
    
    func formatQuantity(_ quantity: Double) -> String {
        return String(format: "%.2f", quantity)
    }
    
    func formatCurrency(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    func formatNumber(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        return numberFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    // MARK: - Public Methods
    func getValidationErrors() -> [IngredientValidationError] {
        return validationErrors
    }
    
    func clearValidationErrors() {
        validationErrors.removeAll()
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
