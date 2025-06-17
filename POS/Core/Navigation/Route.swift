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
