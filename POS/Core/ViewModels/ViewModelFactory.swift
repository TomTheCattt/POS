//import Foundation
//
//final class ViewModelFactory {
//    // MARK: - Singleton
//    static let shared = ViewModelFactory()
//    
//    // MARK: - Properties
//    private var viewModels: [String: Any] = [:]
//    private let environment: AppEnvironment
//    
//    // MARK: - Initialization
//    init(environment: AppEnvironment = AppEnvironment()) {
//        self.environment = environment
//    }
//    
//    // MARK: - Public Methods
//    func resetAll() {
//        viewModels.removeAll()
//    }
//    
//    // MARK: - Private Methods
//    private func getOrCreate<T>(_ type: T.Type, create: () -> T) -> T {
//        let key = String(describing: type)
//        if let existing = viewModels[key] as? T {
//            return existing
//        }
//        let new = create()
//        viewModels[key] = new
//        return new
//    }
//}
//
//@MainActor
//extension ViewModelFactory {
//    private func makeViewModel<T>(create: () -> T) -> T {
//        return getOrCreate(T.self, create: create)
//    }
//    
//    // MARK: - Specific ViewModels
//    func makeAuthenticationViewModel() -> AuthenticationViewModel {
//        makeViewModel {
//            AuthenticationViewModel(source: source)
//        }
//    }
//    
//    func makeHomeViewModel() -> HomeViewModel {
//        makeViewModel()
//    }
//    
//    func makeMenuViewModel() -> MenuViewModel {
//        makeViewModel()
//    }
//    
//    func makeHistoryViewModel() -> HistoryViewModel {
//        makeViewModel()
//    }
//    
//    func makeSettingsViewModel() -> SettingsViewModel {
//        makeViewModel()
//    }
//    
//    func makeAnalyticsViewModel() -> AnalyticsViewModel {
//        makeViewModel()
//    }
//    
//    func makeInventoryViewModel() -> InventoryViewModel {
//        makeViewModel()
//    }
//    
//    func makePrinterViewModel() -> PrinterViewModel {
//        makeViewModel()
//    }
//}
//
