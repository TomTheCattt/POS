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
    @Published private(set) var selectedCategory: String = "All"
    @Published private(set) var menuList: [AppMenu] = []
    @Published private(set) var currentMenu: AppMenu?
    @Published private(set) var menuItems: [MenuItem] = []
    @Published private(set) var categories: [String] = ["All"]
    @Published var isSelectionMode: Bool = false
    @Published var selectedItems: Set<MenuItem> = []
    
    // MARK: - Dependencies
    private let source: SourceModel
    
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
            .store(in: &source.cancellables)
        source.menuListPublisher
            .sink { [weak self] menu in
                guard let self = self,
                      let menu = menu else { return }
                self.menuList = menu
            }
            .store(in: &source.cancellables)
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
    
    func selectMenu(_ menu: AppMenu) {
        self.currentMenu = menu
    }
    
    // MARK: - Menu Management
    func createNewMenu(_ menu: AppMenu, completion: @escaping (Bool) -> Void) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id else { return }
            
            _ = try await source.environment.databaseService.createMenu(menu, userId: userId, shopId: shopId)
            completion(true)
        } catch {
            source.handleError(error, action: "thêm thực đơn mới")
            completion(false)
        }
    }
    
    func updateMenu(_ menu: AppMenu) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let menuId = menu.id else { return }
            
            _ = try await source.environment.databaseService.updateMenu(menu, userId: userId, shopId: shopId, menuId: menuId)
        } catch {
            source.handleError(error, action: "cập nhật thực đơn")
        }
    }
    
    func deleteMenu(_ menu: AppMenu) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let menuId = menu.id else { return }
            
            _ = try await source.environment.databaseService.deleteMenu(userId: userId, shopId: shopId, menuId: menuId)
        } catch {
            source.handleError(error, action: "xoá thực đơn")
        }
    }
    
    func activateMenu() async {
        await source.activateMenu(currentMenu!)
        currentMenu?.isActive = true
    }
    
    func deActivateMenu() async {
        await source.deactivateMenu(currentMenu!)
        currentMenu?.isActive = false
    }
    
    // MARK: - Menu Item Management
    
    func createMenuItem(_ item: MenuItem, in menu: AppMenu, imageData: Data?) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let menuId = menu.id else { return }
            
            var menuItem = item
            
            // Upload ảnh nếu có
            if let imageData = imageData {
                let imageURL = try await source.environment.storageService.uploadImage(
                    imageData,
                    path: "menu/\(shopId)/\(UUID().uuidString)"
                )
                menuItem.imageURL = imageURL
            }
            
            _ = try await source.environment.databaseService.createMenuItem(
                menuItem,
                userId: userId,
                shopId: shopId,
                menuId: menuId
            )
        } catch {
            source.handleError(error, action: "thêm món mới")
        }
    }
    
    func updateMenuItem(_ item: MenuItem, in menu: AppMenu, imageData: Data?) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let menuId = menu.id,
                  let menuItemId = item.id else { return }
            
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
                    recipe: item.recipe,
                    isAvailable: item.isAvailable,
                    imageURL: imageURL,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt
                )
            }
            
            _ = try await source.environment.databaseService.updateMenuItem(
                menuItem,
                userId: menuItemId,
                shopId: userId,
                menuId: shopId,
                menuItemId: menuId
            )
        } catch {
            source.handleError(error, action: "cập nhật món")
        }
    }
    
    func deleteMenuItem(_ item: MenuItem, in menu: AppMenu) async {
        do {
            guard let userId = source.currentUser?.id,
                  let shopId = source.activatedShop?.id,
                  let menuId = menu.id,
                  let itemId = item.id else { return }
            
            // Xóa ảnh nếu có
            if let imageURL = item.imageURL {
                try await source.environment.storageService.deleteImage(at: imageURL)
            }
            
            try await source.environment.databaseService.deleteMenuItem(
                userId: userId,
                shopId: shopId,
                menuId: menuId,
                menuItemId: itemId
            )
        } catch {
            source.handleError(error, action: "xóa món")
        }
    }
    
    func importMenuItems(from url: URL, in menu: AppMenu) async {
        do {
            let data = try Data(contentsOf: url)
            let items = try parseMenuItemsFromCSV(data)
            
            for item in items {
                await createMenuItem(item, in: menu, imageData: nil)
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
    
    func getIngredientUsage(by id: String) async throws -> IngredientUsage? {
        guard let userId = source.currentUser?.id, let activatedShopId = source.activatedShop?.id else {
            return nil
        }
        return try await source.environment.databaseService.getIngredientUsage(userId: userId, shopId: activatedShopId, IngredientUsageId: id)
    }
}

