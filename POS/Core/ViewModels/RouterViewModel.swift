//
//  RouterViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 6/6/25.
//

import Foundation

@MainActor
class RouterViewModel: ObservableObject {
    
    let source: SourceModel?
    
    let authVM: AuthenticationViewModel
    let homeVM: HomeViewModel
    let orderVM: OrderViewModel
    let historyVM: HistoryViewModel
    let revenueRecordVM: RevenueRecordViewModel
    let ingredientVM: IngredientViewModel
    let settingsVM: SettingsViewModel
    let profileVM: ProfileViewModel
    let menuVM: MenuViewModel
    let printerVM: PrinterViewModel
    let passwordVM: PasswordViewModel
    let shopVM: ShopManagementViewModel
    let staffVM: StaffViewModel
    let expenseVM: ExpenseViewModel
    
    init(source: SourceModel) {
        self.source = source
        self.authVM = AuthenticationViewModel(source: source)
        self.homeVM = HomeViewModel(source: source)
        self.orderVM = OrderViewModel(source: source)
        self.historyVM = HistoryViewModel(source: source)
        self.revenueRecordVM = RevenueRecordViewModel(source: source)
        self.ingredientVM = IngredientViewModel(source: source)
        self.settingsVM = SettingsViewModel(source: source)
        self.profileVM = ProfileViewModel(source: source)
        self.menuVM = MenuViewModel(source: source)
        self.printerVM = PrinterViewModel(source: source)
        self.passwordVM = PasswordViewModel(source: source)
        self.shopVM = ShopManagementViewModel(source: source)
        self.staffVM = StaffViewModel(source: source)
        self.expenseVM = ExpenseViewModel(source: source)
    }
}
