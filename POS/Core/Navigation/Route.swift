import Foundation

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
    case updateInventory
    case updateMenu
    case setUpPrinter
    case language
    case theme

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
        case .updateInventory:
            return "updateInventory"
        case .updateMenu:
            return "updateMenu"
        case .language:
            return "language"
        case .theme:
            return "theme"
        case .setUpPrinter:
            return "setUpPrinter"
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

// MARK: - ViewModel Factory Extension
extension Route {
    func makeViewModel(factory: ViewModelFactory = .shared) -> Any {
        switch self {
        case .authentication:
            return factory.makeAuthenticationViewModel()
        case .home:
            return factory.makeHomeViewModel()
        case .menu:
            return factory.makeMenuViewModel()
        case .history:
            return factory.makeHistoryViewModel()
        case .analytics:
            return factory.makeAnalyticsViewModel()
        case .inventory, .updateInventory:
            return factory.makeInventoryViewModel()
        case .settings, .language, .theme:
            return factory.makeSettingsViewModel()
        case .updateMenu:
            return factory.makeMenuViewModel()
        case .note:
            return factory.makeMenuViewModel()
        case .setUpPrinter:
            return factory.makePrinterViewModel()
        }
    }
}
