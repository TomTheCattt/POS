//
//  MenuViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import Combine

// MARK: - Validation Errors
enum MenuValidationError: LocalizedError {
    case invalidName(String)
    case invalidPrice(String)
    case invalidCategory(String)
    case invalidRecipe(String)
    case invalidImage(String)
    case missingRequiredFields(String)
    case duplicateMenuItem(String)
    case insufficientIngredients(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName(let message): return "Lỗi tên món: \(message)"
        case .invalidPrice(let message): return "Lỗi giá: \(message)"
        case .invalidCategory(let message): return "Lỗi danh mục: \(message)"
        case .invalidRecipe(let message): return "Lỗi công thức: \(message)"
        case .invalidImage(let message): return "Lỗi hình ảnh: \(message)"
        case .missingRequiredFields(let message): return "Thiếu thông tin: \(message)"
        case .duplicateMenuItem(let message): return "Món đã tồn tại: \(message)"
        case .insufficientIngredients(let message): return "Thiếu nguyên liệu: \(message)"
        }
    }
}

// MARK: - Menu Item Form State
struct MenuItemFormState {
    var name: String = ""
    var price: String = ""
    var category: String = ""
    var selectedImage: UIImage?
    var showingImagePicker: Bool = false
    var showingRecipeSheet: Bool = false
    var recipe: [Recipe] = []
    var isUploading: Bool = false
    var focusedField: AppTextField?
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(price) != nil &&
        !recipe.isEmpty
    }
}

@MainActor
final class MenuViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var searchKey: String = ""
    @Published private(set) var selectedCategory: String = "All"
    @Published private(set) var menuList: [AppMenu] = []
    @Published private(set) var menuItems: [MenuItem] = []
    @Published private(set) var categories: [String] = ["All"]
    @Published var isSelectionMode: Bool = false
    @Published var selectedItems: Set<MenuItem> = []
    
    // MARK: - Form State
    @Published var menuItemFormState = MenuItemFormState()
    
    // MARK: - Loading States
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isRefreshing: Bool = false
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredMenuItems: [MenuItem] {
        menuItems.filter {
            (selectedCategory == "All" || $0.category == selectedCategory) &&
            (searchKey.isEmpty || $0.name.localizedCaseInsensitiveContains(searchKey))
        }
    }
    
    var actualCategoriesCount: Int {
        Set(menuItems.map { $0.category }).count
    }
    
    var availableMenuItems: [MenuItem] {
        menuItems.filter { $0.isAvailable }
    }
    
    var unavailableMenuItems: [MenuItem] {
        menuItems.filter { !$0.isAvailable }
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        source.menuItemsPublisher
            .sink { [weak self] menuItems in
                guard let self = self,
                      let menuItems = menuItems else { return }
                self.menuItems = menuItems
                updateCategories(from: menuItems)
            }
            .store(in: &cancellables)
        source.menuListPublisher
            .sink { [weak self] menu in
                guard let self = self,
                      let menu = menu else { return }
                self.menuList = menu
            }
            .store(in: &cancellables)
    }
    
    private func updateCategories(from items: [MenuItem]) {
        let uniqueCategories = Set(items.map { $0.category })
        categories = ["All"] + Array(uniqueCategories).sorted()
    }
    
    // MARK: - Public Methods
    func updateSearchKey(_ newValue: String) {
        searchKey = newValue
    }
    
    func updateSelectedCategory(_ category: String) {
        selectedCategory = category
    }
    
    func getMenuItem(by id: String) -> MenuItem? {
        return menuItems.first(where: { $0.id == id })
    }
    
    // MARK: - Form State Management
    func setupInitialData(for menuItem: MenuItem?) {
        if let item = menuItem {
            menuItemFormState.name = item.name
            menuItemFormState.price = String(format: "%.0f", item.price)
            menuItemFormState.category = item.category
            menuItemFormState.recipe = item.recipe
            
            if let url = item.imageURL {
                Task {
                    if let (data, _) = try? await URLSession.shared.data(from: url),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            menuItemFormState.selectedImage = image
                        }
                    }
                }
            }
        } else {
            resetFormState()
        }
    }
    
    func resetFormState() {
        menuItemFormState = MenuItemFormState()
    }
    
    func toggleImagePicker() {
        menuItemFormState.showingImagePicker.toggle()
    }
    
    func toggleRecipeSheet() {
        menuItemFormState.showingRecipeSheet.toggle()
    }
    
    func handleRecipeUpdate(_ recipe: [Recipe]) {
        menuItemFormState.recipe = recipe
    }
    
    func handleCategorySelection(_ category: String) {
        menuItemFormState.category = category
    }
    
    // MARK: - Validation Methods
    private func validateMenuItem(_ item: MenuItem) async throws {
        // Validate name
        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            throw MenuValidationError.invalidName("Tên món không được để trống")
        }
        if trimmedName.count < 2 {
            throw MenuValidationError.invalidName("Tên món phải có ít nhất 2 ký tự")
        }
        if trimmedName.count > 50 {
            throw MenuValidationError.invalidName("Tên món không được vượt quá 50 ký tự")
        }
        if !trimmedName.matches(pattern: "^[a-zA-ZÀ-ỹ0-9\\s\\-&()]+$") {
            throw MenuValidationError.invalidName("Tên món chỉ được chứa chữ cái, số và ký tự đặc biệt cơ bản")
        }
        
        // Validate price
        if item.price <= 0 {
            throw MenuValidationError.invalidPrice("Giá phải lớn hơn 0")
        }
        if item.price > 1000000000 {
            throw MenuValidationError.invalidPrice("Giá không được vượt quá 1 tỷ VND")
        }
        
        // Validate category
        let trimmedCategory = item.category.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCategory.isEmpty {
            throw MenuValidationError.invalidCategory("Danh mục không được để trống")
        }
        if trimmedCategory.count < 2 {
            throw MenuValidationError.invalidCategory("Danh mục phải có ít nhất 2 ký tự")
        }
        if trimmedCategory.count > 30 {
            throw MenuValidationError.invalidCategory("Danh mục không được vượt quá 30 ký tự")
        }
        
        // Validate recipe
        try await validateRecipe(item.recipe)
        
        // Check for duplicate
        if let existingItem = menuItems.first(where: { 
            $0.name.lowercased() == item.name.lowercased() && $0.id != item.id 
        }) {
            throw MenuValidationError.duplicateMenuItem("Món '\(existingItem.name)' đã tồn tại")
        }
    }
    
    private func validateRecipe(_ recipe: [Recipe]) async throws {
        if recipe.isEmpty {
            throw MenuValidationError.invalidRecipe("Vui lòng thêm ít nhất một nguyên liệu vào công thức")
        }
        if recipe.count > 20 {
            throw MenuValidationError.invalidRecipe("Công thức không được vượt quá 20 nguyên liệu")
        }
        
        // Validate each ingredient
        for (index, recipeItem) in recipe.enumerated() {
            if recipeItem.requiredAmount.value <= 0 {
                throw MenuValidationError.invalidRecipe("Nguyên liệu thứ \(index + 1) phải có số lượng lớn hơn 0")
            }
            
            // Check ingredient availability
            if let ingredient = try await getIngredientUsage(by: recipeItem.ingredientId) {
                if !recipeItem.canBeMadeWith(ingredient: ingredient) {
                    throw MenuValidationError.insufficientIngredients("Không đủ nguyên liệu: \(recipeItem.ingredientName)")
                }
            } else {
                throw MenuValidationError.invalidRecipe("Không tìm thấy nguyên liệu: \(recipeItem.ingredientName)")
            }
        }
    }
    
    private func validateImage(_ imageData: Data) throws {
        if imageData.count > 10 * 1024 * 1024 { // 10MB
            throw MenuValidationError.invalidImage("Kích thước ảnh không được vượt quá 10MB")
        }
        
        guard let image = UIImage(data: imageData) else {
            throw MenuValidationError.invalidImage("Định dạng ảnh không hợp lệ")
        }
        
        if image.size.width < 100 || image.size.height < 100 {
            throw MenuValidationError.invalidImage("Kích thước ảnh phải tối thiểu 100x100 pixels")
        }
    }
    
    // MARK: - Menu Management
    func createNewMenu(_ menu: AppMenu) async throws {
        guard let userId = source.currentUser?.id,
              let shopId = source.activatedShop?.id else {
            throw MenuValidationError.missingRequiredFields("Thiếu thông tin người dùng hoặc cửa hàng")
        }
        
        // Validate menu name
        let trimmedName = menu.menuName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            throw MenuValidationError.invalidName("Tên menu không được để trống")
        }
        if trimmedName.count < 2 {
            throw MenuValidationError.invalidName("Tên menu phải có ít nhất 2 ký tự")
        }
        
        _ = try await source.environment.databaseService.createMenu(menu, userId: userId, shopId: shopId)
    }
    
    func updateMenu(_ menu: AppMenu) async throws {
        guard let userId = source.currentUser?.id,
              let shopId = source.activatedShop?.id,
              let menuId = menu.id else {
            throw MenuValidationError.missingRequiredFields("Thiếu thông tin người dùng hoặc cửa hàng")
        }
        
        // Validate menu name
        let trimmedName = menu.menuName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            throw MenuValidationError.invalidName("Tên menu không được để trống")
        }
        
        _ = try await source.environment.databaseService.updateMenu(menu, userId: userId, shopId: shopId, menuId: menuId)
    }
    
    func deleteMenu(_ menu: AppMenu) async throws {
        guard let userId = source.currentUser?.id,
              let shopId = source.activatedShop?.id,
              let menuId = menu.id else {
            throw MenuValidationError.missingRequiredFields("Thiếu thông tin người dùng hoặc cửa hàng")
        }
        
        // Check if menu has items
        let menuItemsInMenu = menuItems.filter { $0.menuId == menuId }
        if !menuItemsInMenu.isEmpty {
            throw MenuValidationError.invalidRecipe("Không thể xóa menu đang chứa món ăn")
        }
        
        _ = try await source.environment.databaseService.deleteMenu(userId: userId, shopId: shopId, menuId: menuId)
    }
    
    func activateMenu(_ menu: AppMenu) async {
        await source.activateMenu(menu)
    }
    
    func deActivateMenu(_ menu: AppMenu) async {
        await source.deactivateMenu(menu)
    }
    
    // MARK: - Menu Item Management with Validation
    func createMenuItem(_ item: MenuItem, in menu: AppMenu, imageData: Data?) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate menu item
            try await validateMenuItem(item)
            
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let menuId = menu.id else {
                throw MenuValidationError.missingRequiredFields("Thiếu thông tin người dùng hoặc cửa hàng")
            }
            
            var menuItem = item
            var uploadedImageURL: URL?
            
            // Process and upload image if exists
            if let imageData = imageData {
                try validateImage(imageData)
                let processedImageData = try await processImage(imageData)
                uploadedImageURL = try await uploadMenuItemImage(processedImageData, shopId: shopId)
                menuItem.imageURL = uploadedImageURL
            }
            
            // Create menu item
            do {
                _ = try await source.environment.databaseService.createMenuItem(
                    menuItem,
                    userId: userId,
                    shopId: shopId,
                    menuId: menuId
                )
            } catch {
                // Rollback: Delete uploaded image if menu item creation fails
                if let imageURL = uploadedImageURL {
                    try? await deleteMenuItemImage(imageURL)
                }
                throw error
            }
            
            // Update availability status
            await updateMenuItemAvailability(menuItem)
            
        } catch {
            source.handleError(error, action: "thêm món mới")
            throw error
        }
    }
    
    func updateMenuItem(_ item: MenuItem, in menu: AppMenu, imageData: Data?) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate menu item
            try await validateMenuItem(item)
            
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let menuId = menu.id,
                  let menuItemId = item.id else {
                throw MenuValidationError.missingRequiredFields("Thiếu thông tin người dùng hoặc cửa hàng")
            }
            
            var menuItem = item
            var uploadedImageURL: URL?
            
            // Handle image update
            if let imageData = imageData {
                try validateImage(imageData)
                
                // Delete old image if exists
                if let oldImageURL = item.imageURL {
                    try await deleteMenuItemImage(oldImageURL)
                }
                
                // Process and upload new image
                let processedImageData = try await processImage(imageData)
                uploadedImageURL = try await uploadMenuItemImage(processedImageData, shopId: shopId)
                menuItem.imageURL = uploadedImageURL
            }
            
            // Update menu item
            do {
                _ = try await source.environment.databaseService.updateMenuItem(
                    menuItem,
                    userId: menuItemId,
                    shopId: userId,
                    menuId: shopId,
                    menuItemId: menuId
                )
            } catch {
                // Rollback: Delete uploaded image if update fails
                if let imageURL = uploadedImageURL {
                    try? await deleteMenuItemImage(imageURL)
                }
                throw error
            }
            
            // Update availability status
            await updateMenuItemAvailability(menuItem)
            
        } catch {
            source.handleError(error, action: "cập nhật món")
            throw error
        }
    }
    
    func deleteMenuItem(_ item: MenuItem, in menu: AppMenu) async throws {
        guard let userId = source.currentUser?.id,
              let shopId = source.activatedShop?.id,
              let menuId = menu.id,
              let itemId = item.id else {
            throw MenuValidationError.missingRequiredFields("Thiếu thông tin người dùng hoặc cửa hàng")
        }
        
        do {
            // Delete image if exists
            if let imageURL = item.imageURL {
                try await deleteMenuItemImage(imageURL)
            }
            
            try await source.environment.databaseService.deleteMenuItem(
                userId: userId,
                shopId: shopId,
                menuId: menuId,
                menuItemId: itemId
            )
        } catch {
            source.handleError(error, action: "xóa món")
            throw error
        }
    }
    
    func deleteMenuItems(_ items: Set<MenuItem>, in menu: AppMenu) async throws {
        try await source.withLoading {
            for item in items {
                try await deleteMenuItem(item, in: menu)
            }
        }
    }
    
    func importMenuItems(from url: URL, in menu: AppMenu) async throws {
        let data = try Data(contentsOf: url)
        let items = try parseMenuItemsFromCSV(data)
        
        for item in items {
            try await createMenuItem(item, in: menu, imageData: nil)
        }
    }
    
    // MARK: - Image Processing
    private func processImage(_ imageData: Data) async throws -> Data {
        // Compress image if needed
        if imageData.count > 1024 * 1024 { // 1MB
            guard let image = UIImage(data: imageData),
                  let compressedData = image.jpegData(compressionQuality: 0.7) else {
                throw MenuValidationError.invalidImage("Không thể nén ảnh")
            }
            return compressedData
        }
        return imageData
    }
    
    private func uploadMenuItemImage(_ imageData: Data, shopId: String) async throws -> URL {
        let path = "menu/\(shopId)/\(UUID().uuidString)"
        return try await source.environment.storageService.uploadImage(imageData, path: path)
    }
    
    private func deleteMenuItemImage(_ imageURL: URL) async throws {
        try await source.environment.storageService.deleteImage(at: imageURL)
    }
    
    // MARK: - Availability Management
    private func updateMenuItemAvailability(_ item: MenuItem) async {
        do {
            var menuItem = item
            let ingredients: [IngredientUsage] = try await source.environment.databaseService.getAllIngredientUsages(
                userId: source.currentUser?.id ?? "",
                shopId: source.activatedShop?.id ?? ""
            )
            
            let ingredientsDict = Dictionary(uniqueKeysWithValues: ingredients.map { ($0.id ?? "", $0) })
            menuItem.updateAvailability(ingredients: ingredientsDict)
            
            if menuItem.isAvailable != item.isAvailable {
                try await source.environment.databaseService.updateMenuItem(
                    menuItem,
                    userId: item.id ?? "",
                    shopId: source.activatedShop?.id ?? "",
                    menuId: item.menuId,
                    menuItemId: item.id ?? ""
                )
            }
        } catch {
            source.handleError(error, action: "cập nhật trạng thái món")
        }
    }
    
    // MARK: - Utility Methods
    private func parseMenuItemsFromCSV(_ data: Data) throws -> [MenuItem] {
        // Implement CSV parsing logic here
        // Return array of MenuItem
        return []
    }
    
    func getIngredientUsage(by id: String) async throws -> IngredientUsage? {
        guard let userId = source.currentUser?.id, let activatedShopId = source.activatedShop?.id else {
            return nil
        }
        return try await source.environment.databaseService.getIngredientUsage(userId: userId, shopId: activatedShopId, IngredientUsageId: id)
    }
    
    // MARK: - Selection Management
    func toggleSelection(for item: MenuItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    func selectAll() {
        selectedItems = Set(menuItems)
    }
    
    func deselectAll() {
        selectedItems.removeAll()
    }
    
    // MARK: - Refresh Data
    func refreshData() async {
        isRefreshing = true
//        defer { isRefreshing = false }
        
        // Trigger data refresh
        //await source.refreshMenuData()
    }
}



