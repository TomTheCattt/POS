import Foundation
import SwiftUI

enum Route: Hashable, Identifiable {
    
    // MARK: - Cases
    
    /// Authentication
    case authentication
    case ownerAuth
    case signIn
    case signUp

    /// Main Features
    case home
    
    case order
    case orderMenuItemCard(MenuItem)
    case orderItem(OrderItem)
    
    case ordersHistory
    case filter
    case orderCard(Order)
    case orderDetail(Order)
    case analytics
    case inventory
    case note(OrderItem)
    
    /// Settings
    case settings
    case addShop
    case ingredientSection
    case ingredientForm(IngredientUsage?)
    case menuSection
    case menuForm(AppMenu?)
    case updateMenuForm
    case menuRow(AppMenu)
    case menuDetail
    case menuItemForm(AppMenu, MenuItem?)
    case menuItemCard(MenuItem)
    case setUpPrinter
    case language
    case theme
    case accountDetail
    case password
    case manageShops

    // MARK: - Identifiable

    var id: String {
        switch self {
        case .authentication:
            return "authentication"
        case .ownerAuth:
            return "ownerAuth"
        case .signIn:
            return "signIn"
        case .signUp:
            return "signUp"
        case .home:
            return "home"
        case .order:
            return "order"
        case .orderMenuItemCard(let menuItem):
            return "menuItem-\(menuItem.id ?? "")"
        case .orderItem(let orderItem):
            return "orderItem-\(orderItem.id)"
        case .ordersHistory:
            return "ordersHistory"
        case .filter:
            return "filter"
        case .orderCard(let order):
            return "order-card-\(order.id ?? "")"
        case .orderDetail(let order):
            return "order-detail-\(order.id ?? "")"
        case .analytics:
            return "analytics"
        case .inventory:
            return "inventory"
        case .note(let orderItem):
            return "note-\(orderItem.id)"
        case .settings:
            return "settings"
        case .addShop:
            return "addShop"
        case .ingredientSection:
            return "ingredientSection"
        case .ingredientForm(let ingredient):
            return "ingredientForm-\(ingredient?.id ?? "")"
        case .menuSection:
            return "menuSection"
        case .menuForm(let menu):
            return "menuForm-\(menu?.id ?? "")"
        case .updateMenuForm:
            return "updateMenuForm"
        case .menuRow(let menu):
            return "menu-\(menu.id ?? "error")"
        case .menuDetail:
            return "menuDetail"
        case .menuItemForm(let menu, let menuItem):
            return "menu-\(menu.id ?? "error")-menuItem-\(menuItem?.id ?? "")"
        case .menuItemCard(let menuItem):
            return "menuItem-\(menuItem.id ?? "")"
        case .language:
            return "language"
        case .theme:
            return "theme"
        case .setUpPrinter:
            return "setUpPrinter"
        case .accountDetail:
            return "accountDetail"
        case .password:
            return "password"
        case .manageShops:
            return "manageShops"
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        lhs.id == rhs.id
    }
}

