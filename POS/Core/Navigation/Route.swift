import Foundation
import SwiftUI

enum Route: Hashable, Identifiable {
    
    // MARK: - Cases
    
    /// Authentication
    case authentication

    /// Main Features
    case home
    case menu
    case history
    case analytics
    case inventory
    case note(OrderItem)
    
    /// Settings
    case settings
    case ingredientSection
    case ingredientForm(IngredientUsage?)
    case menuSection
    case menuForm(AppMenu?)
    case menuDetail(AppMenu)
    case menuItemForm(AppMenu, MenuItem?)
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
        case .home:
            return "home"
        case .menu:
            return "menu"
        case .history:
            return "history"
        case .analytics:
            return "analytics"
        case .inventory:
            return "inventory"
        case .note(let orderItem):
            return "note-\(orderItem.id)"
        case .settings:
            return "settings"
        case .ingredientSection:
            return "ingredientSection"
        case .ingredientForm(let ingredient):
            return "ingredientForm-\(ingredient?.id ?? "")"
        case .menuSection:
            return "menuSection"
        case .menuForm(let menu):
            return "menuForm-\(menu?.id ?? "")"
        case .menuDetail(let menu):
            return "menu-\(menu.id ?? "error")"
        case .menuItemForm(let menu, let menuItem):
            return "menu-\(menu.id ?? "error")-menuItem-\(menuItem?.id ?? "")"
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

