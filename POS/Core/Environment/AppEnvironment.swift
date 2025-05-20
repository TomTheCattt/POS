import Foundation

final class AppEnvironment: ObservableObject {
    // MARK: - Services
    let authService: AuthService
    let networkService: NetworkService
    let storageService: StorageService
    let shopService: ShopService
    let menuService: MenuService
    let orderService: OrderService
    let inventoryService: InventoryService
    let analyticsService: AnalyticsService
    let crashlyticsService: CrashlyticsService
    let settingsService: SettingsService
    let printerService: PrinterService
    
    // MARK: - Initialization
    init(
        authService: AuthService = .shared,
        networkService: NetworkService = .shared,
        storageService: StorageService = .shared,
        shopService: ShopService = .shared,
        menuService: MenuService = .shared,
        orderService: OrderService = .shared,
        inventoryService: InventoryService = .shared,
        analyticsService: AnalyticsService = .shared,
        crashlyticsService: CrashlyticsService = .shared,
        settingsService: SettingsService = .shared,
        printerService: PrinterService = .shared
    ) {
        self.authService = authService
        self.networkService = networkService
        self.storageService = storageService
        self.shopService = shopService
        self.menuService = menuService
        self.orderService = orderService
        self.inventoryService = inventoryService
        self.analyticsService = analyticsService
        self.crashlyticsService = crashlyticsService
        self.settingsService = settingsService
        self.printerService = printerService
    }
}
