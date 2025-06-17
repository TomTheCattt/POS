//import Foundation
//import SwiftUI
//
//// MARK: - Core Protocols
//protocol AppNavigable: Hashable, Identifiable {
//    var id: String { get }
//    var themeColor: AppThemeColorEnum { get }
//}
//
//protocol MenuItemRepresentable {
//    var title: String { get }
//    var icon: String { get }
//}
//
//// MARK: - Theme System
//enum AppThemeColorEnum: CaseIterable {
//    case global, order, history, expense, revenue, settings
//    
//    func resolve(from colors: AppThemeColors) -> TabThemeColor {
//        switch self {
//        case .global: return colors.global
//        case .order: return colors.order
//        case .history: return colors.history
//        case .expense: return colors.expense
//        case .revenue: return colors.revenue
//        case .settings: return colors.settings
//        }
//    }
//}
//
//// MARK: - Main App Route
//enum AppRoute: AppNavigable, MenuItemRepresentable {
//    case authentication
//    case order(OrderRoute)
//    case history(HistoryRoute)
//    case expense(ExpenseRoute)
//    case revenue(RevenueRoute)
//    case settings(SettingsRoute)
//    
//    var id: String {
//        switch self {
//        case .authentication:
//            return "auth"
//        case .order(let route):
//            return "order_\(route.id)"
//        case .history(let route):
//            return "history_\(route.id)"
//        case .expense(let route):
//            return "expense_\(route.id)"
//        case .revenue(let route):
//            return "revenue_\(route.id)"
//        case .settings(let route):
//            return "settings_\(route.id)"
//        }
//    }
//    
//    var themeColor: AppThemeColorEnum {
//        switch self {
//        case .authentication:
//            return .global
//        case .order:
//            return .order
//        case .history:
//            return .history
//        case .expense:
//            return .expense
//        case .revenue:
//            return .revenue
//        case .settings:
//            return .settings
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .authentication:
//            return "person.fill"
//        case .order:
//            return "square.grid.2x2"
//        case .history:
//            return "clock.arrow.circlepath"
//        case .expense:
//            return "cube.box.fill"
//        case .revenue:
//            return "chart.bar.fill"
//        case .settings:
//            return "gearshape.fill"
//        }
//    }
//    
//    var title: String {
//        switch self {
//        case .authentication:
//            return "Đăng nhập"
//        case .order:
//            return "Thực đơn"
//        case .history:
//            return "Lịch sử"
//        case .expense:
//            return "Kho hàng"
//        case .revenue:
//            return "Thống kê"
//        case .settings:
//            return "Cài đặt"
//        }
//    }
//    
//    // MARK: - Helper Methods
//    static var mainRoutes: [AppRoute] {
//        [
//            .order(.main),
//            .history(.main),
//            .expense(.main(nil)),
//            .revenue(.main),
//            .settings(.main)
//        ]
//    }
//    
//    func resolveThemeColors(from style: AppThemeStyle) -> TabThemeColor {
//        return themeColor.resolve(from: style.colors)
//    }
//    
//    var currentThemeColors: TabThemeColor {
//        return resolveThemeColors(from: SettingsService.shared.currentThemeStyle)
//    }
//}
//
//// MARK: - Order Routes
//enum OrderRoute: AppNavigable {
//    case main
//    case orderSummary
//    case note(OrderItem)
//    case addCustomer
//    
//    var id: String {
//        switch self {
//        case .main:
//            return "main"
//        case .orderSummary:
//            return "order_summary"
//        case .note(let item):
//            return "note_\(item.id)"
//        case .addCustomer:
//            return "add_customer"
//        }
//    }
//    
//    var themeColor: AppThemeColorEnum { .order }
//}
//
//// MARK: - History Routes
//enum HistoryRoute: AppNavigable {
//    case main
//    case orderDetail(Order)
//    
//    var id: String {
//        switch self {
//        case .main:
//            return "main"
//        case .orderDetail(let order):
//            return "detail_\(order.id ?? "unknown")" // Fixed: better fallback
//        }
//    }
//    
//    var themeColor: AppThemeColorEnum { .history }
//}
//
//// MARK: - Expense Routes
//enum ExpenseRoute: AppNavigable {
//    case main(Shop?)
//    
//    var id: String {
//        switch self {
//        case .main(let shop):
//            return "expense_\(shop?.id ?? "unknown")"
//        }
//    }
//    var themeColor: AppThemeColorEnum { .expense }
//}
//
//// MARK: - Revenue Routes
//enum RevenueRoute: AppNavigable {
//    case main
//    
//    var id: String {
//        switch self {
//        case .main:
//            return "main"
//        }
//    }
//    var themeColor: AppThemeColorEnum { .revenue }
//}
//
//// MARK: - Settings Routes
//enum SettingsRoute: AppNavigable {
//    case main
//    case profile(ProfileRoute)
//    case manageShops(ShopRoute)
//    case printer(PrinterRoute)
//    case language(LanguageRoute)
//    case theme(ThemeRoute)
//    
//    var id: String {
//        switch self {
//        case .main:
//            return "settings_main"
//        case .profile(let route):
//            return "profile_\(route.id)"
//        case .manageShops(let route):
//            return "shops_\(route.id)"
//        case .printer(let route):
//            return "printer_\(route.id)"
//        case .language(let route):
//            return "language_\(route.id)"
//        case .theme(let route):
//            return "theme_\(route.id)"
//        }
//    }
//    
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//// MARK: - Profile Routes
//enum ProfileRoute: String, CaseIterable, AppNavigable {
//    case detail
//    case password
//    
//    var id: String { rawValue }
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//// MARK: - Shop Routes
//enum ShopRoute: AppNavigable {
//    case add
//    case addVoucher(Shop)
//    case detail(Shop)
//    case manage
//    
//    var id: String {
//        switch self {
//        case .add:
//            return "shop_add"
//        case .addVoucher(let shop):
//            return "shop_add_voucher_\(shop.id ?? "unknown")"
//        case .detail(let shop):
//            return "shop_detail_\(shop.id ?? "unknown")"
//        case .manage:
//            return "shop_manage"
//        }
//    }
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//// MARK: - Printer Routes
//enum PrinterRoute: String, CaseIterable, AppNavigable {
//    case setup
//    
//    var id: String { rawValue }
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//// MARK: - Language Routes
//enum LanguageRoute: String, CaseIterable, AppNavigable {
//    case main
//    
//    var id: String { rawValue }
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//// MARK: - Theme Routes
//enum ThemeRoute: String, CaseIterable, AppNavigable {
//    case main
//    
//    var id: String { rawValue }
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//// MARK: - Additional Routes (Currently Unused)
//enum MenuRoute: String, CaseIterable, AppNavigable {
//    case section
//    case form
//    case detail
//    case itemForm
//    case itemCard
//    
//    var id: String { rawValue }
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//enum StaffRoute: String, CaseIterable, AppNavigable {
//    case main
//    
//    var id: String { rawValue }
//    var themeColor: AppThemeColorEnum { .settings }
//}
//
//// MARK: - Settings Categories & Options
//enum SettingsCategory: String, CaseIterable, Identifiable, MenuItemRepresentable {
//    case account, shops, printer, language, theme
//    
//    var id: String { rawValue }
//    
//    var title: String {
//        switch self {
//        case .account: return "Tài khoản"
//        case .shops: return "Quản lý cửa hàng"
//        case .printer: return "Cài đặt máy in"
//        case .language: return "Ngôn ngữ"
//        case .theme: return "Giao diện"
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .account: return "person.fill"
//        case .shops: return "building.2.fill"
//        case .printer: return "printer.fill"
//        case .language: return "globe"
//        case .theme: return "paintbrush.fill"
//        }
//    }
//    
//    var iconColor: Color {
//        switch self {
//        case .account: return .blue
//        case .shops: return .orange
//        case .printer: return .purple
//        case .language: return .green
//        case .theme: return .pink
//        }
//    }
//    
//    var options: [SettingsOption] {
//        switch self {
//        case .account: return AccountOption.allCases.map { .account($0) }
//        case .shops: return ShopOption.allCases.map { .shop($0) }
//        case .printer, .language, .theme: return []
//        }
//    }
//}
//
//enum SettingsOption: Hashable, Identifiable, MenuItemRepresentable {
//    case account(AccountOption)
//    case shop(ShopOption)
//    
//    var id: String {
//        switch self {
//        case .account(let option): return "account_\(option.rawValue)"
//        case .shop(let option): return "shop_\(option.rawValue)"
//        }
//    }
//    
//    var title: String {
//        switch self {
//        case .account(let option): return option.title
//        case .shop(let option): return option.title
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .account(let option): return option.icon
//        case .shop(let option): return option.icon
//        }
//    }
//    
//    var iconColor: Color {
//        switch self {
//        case .account(let option): return option.iconColor
//        case .shop(let option): return option.iconColor
//        }
//    }
//}
//
//// MARK: - Account Options
//enum AccountOption: String, CaseIterable, MenuItemRepresentable {
//    case profile, security, notifications, privacy
//
//    var title: String {
//        switch self {
//        case .profile: return "Thông tin cá nhân"
//        case .security: return "Bảo mật"
//        case .notifications: return "Thông báo"
//        case .privacy: return "Quyền riêng tư"
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .profile: return "person.fill"
//        case .security: return "lock.fill"
//        case .notifications: return "bell.fill"
//        case .privacy: return "hand.raised.fill"
//        }
//    }
//    
//    var iconColor: Color {
//        switch self {
//        case .profile: return .blue
//        case .security: return .red
//        case .notifications: return .orange
//        case .privacy: return .purple
//        }
//    }
//}
//
//// MARK: - Shop Options
//enum ShopOption: String, CaseIterable, MenuItemRepresentable {
//    case locations, menu, inventory, staff
//
//    var title: String {
//        switch self {
//        case .locations: return "Danh sách cửa hàng"
//        case .menu: return "Quản lý thực đơn"
//        case .inventory: return "Kho hàng"
//        case .staff: return "Nhân viên"
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .locations: return "building.2.fill"
//        case .menu: return "list.bullet.rectangle.fill"
//        case .inventory: return "shippingbox.fill"
//        case .staff: return "person.2.fill"
//        }
//    }
//    
//    var iconColor: Color {
//        switch self {
//        case .locations: return .orange
//        case .menu: return .green
//        case .inventory: return .blue
//        case .staff: return .purple
//        }
//    }
//}
//
//

enum Route: Hashable, Identifiable, Codable {
    
    // MARK: - Cases
    
    /// Authentication
    case authentication
    case home
    
    /// Main Features
    
    /// Order Feature
    case order
    /// Order Sub Feature
    case orderSummary
    case orderItem(OrderItem)
    case note(OrderItem)
    case addCustomer
    
    /// History Feature
    case ordersHistory
    /// History Sub Feature
    case orderDetail(Order)
    case orderMenuItemCardIphone(MenuItem)
    case orderMenuItemCardIpad(MenuItem)
    
    /// Revenue Feature
    case revenue(Shop?)
    
    /// Expense Feature
    case expense
    
    /// Settings Feature
    case settings
    
    /// Settings Sub Feature
    
    /// Profile
    case accountDetail
    case password
    
    /// manage shops
    case manageShops
    case shopDetail(Shop)
    case shopRow(Shop)
    case staff(Shop?)
    
    /// menu section
    case menuSection(Shop?)
    case menuForm(AppMenu?)
    case menuItemForm(AppMenu, MenuItem?)
    case menuItemCard(MenuItem)
    case menuDetail(AppMenu)
    case menuRow(AppMenu)
    
    /// ingredient section
    case ingredientSection(Shop?)
    case ingredientForm(IngredientUsage?)
    
    /// Printer
    case setUpPrinter
    
    /// Language
    case language
    
    /// Theme
    case theme
    
    /// Add Shop
    case addShop(Shop?)
    case addVoucher
    
    case ownerAuth
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        
        // Tìm route tương ứng với id
        if let route = Route.allCases.first(where: { $0.id == id }) {
            self = route
        } else {
            // Nếu không tìm thấy, trả về route mặc định
            self = .home
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
    
    // MARK: - Static Properties
    
    static var allCases: [Route] {
        [
            .authentication,
            .home,
            .order,
            .orderSummary,
            .ordersHistory,
            .expense,
            .revenue(nil),
            .settings,
            .accountDetail,
            .password,
            .manageShops,
            .setUpPrinter,
            .language,
            .theme,
            .addVoucher,
            .ownerAuth
        ]
    }
    
    // MARK: - Identifiable
    
    var id: String {
        switch self {
        case .shopDetail(let shop): return "shopDetail-\(shop.id ?? "unknown")"
        case .shopRow(let shop): return "shopRow-\(shop.id ?? "unknown")"
        case .menuDetail(let menu): return "menuDetail-\(menu.id ?? "unknown")"
        case .menuRow(let menu): return "menuRow-\(menu.id ?? "unknown")"
        case .addVoucher: return "addVoucher"
        case .menuItemCard(let menuItem): return "menuItemCard-\(menuItem.id ?? "unknown")"
        case .staff(let shop): return "staff-.\(shop?.id ?? "unknown")"
        case .authentication: return "auth"
        case .home: return "home"
        case .ownerAuth: return "ownerAuth"
        case .order: return "order"
        case .ordersHistory: return "ordersHistory"
        case .orderSummary: return "orderSummary"
        case .orderDetail(let order): return "order-detail-\(order.id ?? "unknown")"
        case .revenue(let shop): return "revenue-for-\(shop?.id ?? "unknown")"
        case .expense: return "expense"
        case .note(let orderItem): return "note-\(orderItem.id)"
        case .settings: return "settings"
        case .addShop(let shop): return "addShop-\(shop?.id ?? "")"
        case .ingredientSection: return "ingredientSection"
        case .ingredientForm(let ingredient): return "ingredientForm-\(ingredient?.id ?? "unknown")"
        case .menuSection: return "menuSection"
        case .menuForm(let menu): return "menuForm-\(menu?.id ?? "")"
        case .menuItemForm(let menu, let menuItem): return "menu-\(menu.id ?? "error")-menuItem-\(menuItem?.id ?? "unknown")"
        case .language: return "language"
        case .theme: return "theme"
        case .setUpPrinter: return "setUpPrinter"
        case .accountDetail: return "accountDetail"
        case .password: return "password"
        case .manageShops: return "manageShops"
        case .addCustomer: return "addCustomer"
        case .orderItem(let orderItem): return "OrderItem-\(orderItem.id)"
        case .orderMenuItemCardIphone(let menuItem): return "MenuItem-\(menuItem.id ?? "unknown")"
        case .orderMenuItemCardIpad(let menuItem): return "MenuItem-\(menuItem.id ?? "unknown")"
        }
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        lhs.id == rhs.id
    }
    
    static var mainFeature: [Route] {
        [
            .order,
            .ordersHistory,
            .expense,
            .revenue(nil),
            .settings
        ]
    }
    
    var title: String {
        switch self {
        case .order: return "Thực đơn"
        case .ordersHistory: return "Lịch sử"
        case .expense: return "Thu chi"
        case .revenue: return "Doanh thu"
        case .settings: return "Cài đặt"
        default: return "Không hỗ trợ"
        }
    }
    
    var icon: String {
        switch self {
        case .order: return "Thực đơn"
        case .ordersHistory: return "Lịch sử"
        case .expense: return "Thu chi"
        case .revenue: return "Doanh thu"
        case .settings: return "Cài đặt"
        default: return "Không hỗ trợ"
        }
    }
}
