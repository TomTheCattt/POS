import Foundation
import Combine

protocol BaseViewModel: ObservableObject {
    associatedtype Environment
    var environment: Environment { get }
    var cancellables: Set<AnyCancellable> { get set }
    
    // Common properties
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var showError: Bool { get set }
    
    init(environment: Environment)
    
    // Common methods
    func handleError(_ error: Error)
    func showLoading(_ isLoading: Bool)
}

extension BaseViewModel {
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            self.errorMessage = appError.localizedDescription
        } else {
            self.errorMessage = error.localizedDescription
        }
        self.showError = true
    }
    
    func showLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}

extension BaseViewModel where Environment == AppEnvironment {
    // MARK: - Service Access
    var authService: AuthService { environment.authService }
    var networkService: NetworkService { environment.networkService }
    var storageService: StorageService { environment.storageService }
    var shopService: ShopService { environment.shopService }
    var menuService: MenuService { environment.menuService }
    var orderService: OrderService { environment.orderService }
    var inventoryService: InventoryService { environment.inventoryService }
    var analyticsService: AnalyticsService { environment.analyticsService }
    var crashlyticsService: CrashlyticsService { environment.crashlyticsService }
    var settingsService: SettingsService { environment.settingsService }
    var printerSerivce: PrinterService { environment.printerService }
}
