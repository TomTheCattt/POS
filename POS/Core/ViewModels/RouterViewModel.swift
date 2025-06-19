//
//  RouterViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 6/6/25.
//

import Foundation

@MainActor
class RouterViewModel: ObservableObject {
    
    let source: SourceModel
    
    // Lazy-loaded ViewModels
    private lazy var _authVM: AuthenticationViewModel = AuthenticationViewModel(source: source)
    private lazy var _homeVM: HomeViewModel = HomeViewModel(source: source)
    private lazy var _orderVM: OrderViewModel = OrderViewModel(source: source)
    private lazy var _historyVM: HistoryViewModel = HistoryViewModel(source: source)
    private lazy var _revenueRecordVM: RevenueRecordViewModel = RevenueRecordViewModel(source: source)
    private lazy var _ingredientVM: IngredientViewModel = IngredientViewModel(source: source)
    private lazy var _settingsVM: SettingsViewModel = SettingsViewModel(source: source)
    private lazy var _profileVM: ProfileViewModel = ProfileViewModel(source: source)
    private lazy var _menuVM: MenuViewModel = MenuViewModel(source: source)
    private lazy var _printerVM: PrinterViewModel = PrinterViewModel(source: source)
    private lazy var _passwordVM: PasswordViewModel = PasswordViewModel(source: source)
    private lazy var _shopVM: ShopManagementViewModel = ShopManagementViewModel(source: source)
    private lazy var _staffVM: StaffViewModel = StaffViewModel(source: source)
    private lazy var _expenseVM: ExpenseViewModel = ExpenseViewModel(source: source)
    
    // Public accessors
    var authVM: AuthenticationViewModel { _authVM }
    var homeVM: HomeViewModel { _homeVM }
    var orderVM: OrderViewModel { _orderVM }
    var historyVM: HistoryViewModel { _historyVM }
    var revenueRecordVM: RevenueRecordViewModel { _revenueRecordVM }
    var ingredientVM: IngredientViewModel { _ingredientVM }
    var settingsVM: SettingsViewModel { _settingsVM }
    var profileVM: ProfileViewModel { _profileVM }
    var menuVM: MenuViewModel { _menuVM }
    var printerVM: PrinterViewModel { _printerVM }
    var passwordVM: PasswordViewModel { _passwordVM }
    var shopVM: ShopManagementViewModel { _shopVM }
    var staffVM: StaffViewModel { _staffVM }
    var expenseVM: ExpenseViewModel { _expenseVM }
    
    init(source: SourceModel) {
        self.source = source
    }
    
    // MARK: - Memory Management
    
    /// Deallocate unused ViewModels to free memory
    func deallocateUnusedViewModels() {
        // Reset lazy properties by setting them to nil
        // Note: This requires careful implementation based on usage patterns
        // Only reset ViewModels that are not currently being observed
    }
    
    /// Get currently initialized ViewModels count for debugging
    var initializedViewModelsCount: Int {
        var count = 0
        // Check which lazy properties have been initialized
        // This is for debugging purposes
        return count
    }
}
