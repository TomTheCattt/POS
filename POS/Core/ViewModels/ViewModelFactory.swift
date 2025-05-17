import Foundation

final class ViewModelFactory {
    // MARK: - Singleton
    static let shared = ViewModelFactory()
    
    // MARK: - Properties
    private var viewModels: [String: Any] = [:]
    private let environment: AppEnvironment
    
    // MARK: - Initialization
    init(environment: AppEnvironment = AppEnvironment()) {
        self.environment = environment
    }
    
    // MARK: - Public Methods
    func resetAll() {
        viewModels.removeAll()
    }
    
    // MARK: - Generic ViewModel Creation
    func makeViewModel<T: BaseViewModel>() -> T where T.Environment == AppEnvironment {
        return getOrCreate(T.self) {
            T(environment: environment)
        }
    }
    
    // MARK: - Specific ViewModels
    func makeAuthenticationViewModel() -> AuthenticationViewModel {
        return makeViewModel()
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return makeViewModel()
    }
    
    func makeMenuViewModel() -> MenuViewModel {
        return makeViewModel()
    }
    
    func makeHistoryViewModel() -> HistoryViewModel {
        return makeViewModel()
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        return makeViewModel()
    }
    
    func makeAnalyticsViewModel() -> AnalyticsViewModel {
        return makeViewModel()
    }
    
    func makeInventoryViewModel() -> InventoryViewModel {
        return makeViewModel()
    }
    
    func makePrinterViewModel() -> PrinterViewModel {
        return makeViewModel()
    }
    
    // MARK: - Private Methods
    private func getOrCreate<T>(_ type: T.Type, create: () -> T) -> T {
        let key = String(describing: type)
        if let existing = viewModels[key] as? T {
            return existing
        }
        let new = create()
        viewModels[key] = new
        return new
    }
} 
