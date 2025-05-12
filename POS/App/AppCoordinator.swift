//
//  AppCoordinator.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Combine
import SwiftUI

// MARK: - Navigation Types

enum PresentationType {
    case push, sheet, fullScreenCover, overlay, tab(Int)
    
    var animation: Animation {
        switch self {
        case .push:
            return .spring(response: 0.35, dampingFraction: 0.86)
        case .sheet:
            return .easeInOut(duration: 0.3)
        case .fullScreenCover:
            return .easeInOut(duration: 0.4)
        case .overlay:
            return .easeOut(duration: 0.25)
        case .tab:
            return .easeInOut(duration: 0.2)
        }
    }
}

enum AppDestination: Hashable {
    // Auth
    case home, authentication, forgotPassword, verifyEmailSent
    
    // Home
    case homeTab(HomeTab)
    
    // Detail
    case orderDetail(Order), inventoryDetail(InventoryItem)
    
    // Hash
    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine(0)
        case .authentication:
            hasher.combine(1)
        case .forgotPassword:
            hasher.combine(2)
        case .verifyEmailSent:
            hasher.combine(3)
        case .homeTab(let selectedOption):
            hasher.combine(4)
            hasher.combine(selectedOption.rawValue)
        case .orderDetail(let order):
            hasher.combine(5)
            hasher.combine(order.id)
        case .inventoryDetail(let inventory):
            hasher.combine(6)
            hasher.combine(inventory.id)
        }
    }
    
    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home):
            return true
        case (.authentication, .authentication):
            return true
        case (.forgotPassword, .forgotPassword):
            return true
        case (.verifyEmailSent, .verifyEmailSent):
            return true
        case (.homeTab(let lSelectedOption), .homeTab(let rSelectedOption)):
            return lSelectedOption == rSelectedOption
        case (.orderDetail(let lOrder), .orderDetail(let rOrder)):
            return lOrder == rOrder
        case (.inventoryDetail(let lInventoryItem), .inventoryDetail(let rInventoryItem)):
            return lInventoryItem == rInventoryItem
        default:
            return false
        }
    }
}

enum AppIcon: String {
    case menu = "list.bullet"
    case history = "clock.arrow.circlepath"
    case inventory = "shippingbox"
    case analytics = "chart.bar"
    case settings = "gear"
    
    var name: String {
        return self.rawValue
    }
}

enum HomeTab: Int, CaseIterable, Identifiable {
    case menu = 0, history, inventory, analytics, settings
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .menu:
            return "Menu"
        case .history:
            return "History"
        case .inventory:
            return "Inventory"
        case .analytics:
            return "Analytics"
        case .settings:
            return "Settings"
        }
    }
    
    var icon: AppIcon {
        switch self {
        case .menu:
            return .menu
        case .history:
            return .history
        case .inventory:
            return .inventory
        case .analytics:
            return .analytics
        case .settings:
            return .settings
        }
    }
    
    var destination: AppDestination {
        switch self {
        case .menu:
            return .homeTab(.menu)
        case .history:
            return .homeTab(.history)
        case .inventory:
            return .homeTab(.inventory)
        case .analytics:
            return .homeTab(.analytics)
        case .settings:
            return .homeTab(.settings)
        }
    }
}

// MARK: - Loading State Management
enum LoadingState: Equatable {
    case idle
    case loading(destination: AppDestination)
    case loaded
    case failed(error: String)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loaded, .loaded):
            return true
        case (.loading(let lhsDest), .loading(let rhsDest)):
            return lhsDest == rhsDest
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Dependency Injection
protocol DependencyContainer {
    func provideHomeViewModel() -> HomeViewModel
    func provideAuthenticationViewModel() -> AuthenticationViewModel
    //    func provideOrderDetailViewModel(for order: Order) -> OrderDetailViewModel
    //    func provideInventoryDetailViewModel(for item: InventoryItem) -> InventoryDetailViewModel
}

class AppDependencyContainer: DependencyContainer {
    // Services can be injected here
    private let authService: AuthServiceProtocol
    //    private let orderService: OrderServiceProtocol
    //    private let inventoryService: InventoryServiceProtocol
    
    init(
        authService: AuthServiceProtocol = AuthService()
        //        orderService: OrderServiceProtocol = OrderService(),
        //        inventoryService: InventoryServiceProtocol = InventoryService()
    ) {
        self.authService = authService
        //        self.orderService = orderService
        //        self.inventoryService = inventoryService
    }
    
    func provideHomeViewModel() -> HomeViewModel {
        return HomeViewModel(authManager: AuthManager())
        //        return HomeViewModel(orderService: orderService)
    }
    
    func provideAuthenticationViewModel() -> AuthenticationViewModel {
        return AuthenticationViewModel(authManager: AuthManager())
    }
    
    //    func provideOrderDetailViewModel(for order: Order) -> OrderDetailViewModel {
    //        return OrderDetailViewModel(order: order, orderService: orderService)
    //    }
    
    //    func provideInventoryDetailViewModel(for item: InventoryItem) -> InventoryDetailViewModel {
    //        return InventoryDetailViewModel(item: item, inventoryService: inventoryService)
    //    }
}

// MARK: - Navigation Configuration
struct NavigationConfig {
    var showBackButton: Bool = false
    var customBackAction: (() -> Void)?
    var title: String?
    var subtitle: String?
}

// MARK: - Coordinator
protocol AppCoordinatorProtocol: AnyObject {
    var navigationPath: NavigationPath { get set }
    var selectedTab: HomeTab { get set }
    var loadingState: LoadingState { get }
    var navigationConfig: NavigationConfig { get set }
    
    func navigateTo(_ destination: AppDestination, using presentationType: PresentationType, withConfig config: NavigationConfig?)
    func navigateToRoot(_ destination: AppDestination)
    func navigateBack()
    func popToLevel(_ level: Int)
    func dismissSheet()
    func dismissCover()
    func startLoading(for destination: AppDestination)
    func finishLoading()
    func failLoading(with error: String)
}

class AppCoordinator: ObservableObject, AppCoordinatorProtocol {
    
    // MARK: Navigation State
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: HomeTab = .menu
    @Published var navigationConfig = NavigationConfig()
    
    // MARK: Sheet Presentation State
    @Published var activeSheet: AppDestination?
    @Published var isSheetPresented = false
    
    // MARK: Full Screen Cover State
    @Published var activeCover: AppDestination?
    @Published var isCoverPresented = false
    
    //MARK: Overlay State
    @Published var activeOverlay: AppDestination?
    @Published var isOverlayPresented = false
    
    // MARK: Loading State
    @Published var loadingState: LoadingState = .idle
    @Published var isLoading: Bool = false
    
    // MARK: Split View State (for iPad/Mac)
    @Published var selectedSidebarItem: SidebarItem?
    @Published var selectedDetailItem: DetailItem?
    
    typealias SidebarItem = String
    typealias DetailItem = String
    
    private let dependencies: DependencyContainer
    
    private var cancellables = Set<AnyCancellable>()
    
    private var overlayTimer: AnyCancellable?
    private var loadingTimer: AnyCancellable?
    
    init(dependencies: DependencyContainer = AppDependencyContainer()) {
        self.dependencies = dependencies
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        overlayTimer?.cancel()
        loadingTimer?.cancel()
    }
    
    // MARK: - Loading Management
    
    func startLoading(for destination: AppDestination) {
        loadingState = .loading(destination: destination)
        isLoading = true
    }
    
    func finishLoading() {
        loadingState = .loaded
        isLoading = false
    }
    
    func failLoading(with error: String) {
        loadingState = .failed(error: error)
        isLoading = false
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a destination using the specified presentation type
    func navigateTo(_ destination: AppDestination, using presentationType: PresentationType = .push, withConfig config: NavigationConfig? = nil) {
        // Set loading state
        startLoading(for: destination)
        
        // Update navigation config if provided
        if let config = config {
            navigationConfig = config
        }
        
        // The actual navigation happens after a small delay to ensure loading is visible
        // Cancel any previous timer to avoid race conditions
        loadingTimer?.cancel()
        
        // First show the loading state
        isLoading = true
        loadingState = .loading(destination: destination)
        
        // After a short delay, perform the actual navigation
        loadingTimer = Just(())
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Apply the appropriate animation for navigation
                withAnimation(presentationType.animation) {
                    switch presentationType {
                    case .push:
                        self.navigationPath.append(destination)
                    case .sheet:
                        self.activeSheet = destination
                        self.isSheetPresented = true
                    case .fullScreenCover:
                        self.activeCover = destination
                        self.isCoverPresented = true
                    case .overlay:
                        self.overlayTimer?.cancel()
                        
                        self.activeOverlay = destination
                        self.isOverlayPresented = true
                        
                        self.overlayTimer = Just(())
                            .delay(for: .seconds(2), scheduler: RunLoop.main)
                            .sink { [weak self] _ in
                                self?.dismissOverlay()
                            }
                    case .tab(let index):
                        if let tab = HomeTab(rawValue: index) {
                            self.selectedTab = tab
                        }
                    }
                }
                
                // Keep the loading visible for a bit after navigation to ensure data is loaded
                Just(())
                    .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                    .sink { [weak self] _ in
                        self?.finishLoading()
                    }
                    .store(in: &self.cancellables)
            }
    }
    
    /// Navigate to a destination and clear the existing navigation stack
    func navigateToRoot(_ destination: AppDestination) {
        // Start loading
        startLoading(for: destination)
        
        // Cancel any existing timer
        loadingTimer?.cancel()
        
        // Show loading state first
        isLoading = true
        loadingState = .loading(destination: destination)
        
        // Perform the navigation after a short delay
        loadingTimer = Just(())
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                withAnimation(.easeInOut) {
                    self.navigationPath.removeLast(self.navigationPath.count)
                    if destination != .home {
                        self.navigationPath.append(destination)
                    }
                }
                
                // Keep loading visible for a bit after navigation
                Just(())
                    .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                    .sink { [weak self] _ in
                        self?.finishLoading()
                    }
                    .store(in: &self.cancellables)
            }
    }
    
    /// Navigate back one level in the navigation stack
    func navigateBack() {
        if !navigationPath.isEmpty {
            if let customBackAction = navigationConfig.customBackAction {
                customBackAction()
            } else {
                withAnimation(.easeInOut) {
                    navigationPath.removeLast()
                }
            }
        }
    }
    
    /// Pop to a specific level in the navigation stack
    func popToLevel(_ level: Int) {
        guard navigationPath.count > level else { return }
        let levelsToRemove = navigationPath.count - level
        
        withAnimation(.easeInOut) {
            navigationPath.removeLast(levelsToRemove)
        }
    }
    
    /// Dismiss the active sheet with animation
    func dismissSheet() {
        withAnimation(.easeOut(duration: 0.3)) {
            isSheetPresented = false
        }
        
        // Use Combine's delay instead of DispatchQueue for better control
        Just(())
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.activeSheet = nil
            }
            .store(in: &cancellables)
    }
    
    /// Dismiss the active full screen cover with animation
    func dismissCover() {
        withAnimation(.easeOut(duration: 0.3)) {
            isCoverPresented = false
        }
        
        // Use Combine's delay instead of DispatchQueue for better control
        Just(())
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.activeCover = nil
            }
            .store(in: &cancellables)
    }
    
    /// Dismiss overlay
    func dismissOverlay() {
        // Cancel the timer if it's still active
        overlayTimer?.cancel()
        overlayTimer = nil
        
        withAnimation(.easeOut(duration: 0.25)) {
            isOverlayPresented = false
        }
        
        Just(())
            .delay(for: .seconds(0.25), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.activeOverlay = nil
            }
            .store(in: &cancellables)
        
    }
    
    // MARK: - Split View Navigation (iPad/Mac)
    
    func selectSidebarItem(_ item: SidebarItem) {
        withAnimation(.spring()) {
            selectedSidebarItem = item
            // Reset detail selection when changing sidebar item
            selectedDetailItem = nil
        }
    }
    
    func selectDetailItem(_ item: DetailItem) {
        withAnimation(.easeInOut) {
            selectedDetailItem = item
        }
    }
}

// MARK: - View Factory with Dependency Injection
struct ViewFactory {
    private let coordinator: AppCoordinator
    private let dependencies = AppDependencyContainer()
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    @ViewBuilder
    func viewForDestination(_ destination: AppDestination) -> some View {
        switch destination {
        case .home:
            HomeView(viewModel: dependencies.provideHomeViewModel(), coordinator: coordinator)
        case .authentication:
            AuthenticationView(viewModel: dependencies.provideAuthenticationViewModel(), coordinator: coordinator)
        case .forgotPassword:
            ForgotPasswordView()
        case .verifyEmailSent:
            VerifyEmailSentView()
        case .homeTab(let homeTab):
            switch homeTab {
            case .menu:
                MenuView()
            case .history:
                Text("History")
            case .inventory:
                Text("Inventory")
            case .analytics:
                Text("Analytics")
            case .settings:
                Text("Settings")
            }
        case .orderDetail(let order):
            //            OrderDetailView(viewModel: dependencies.provideOrderDetailViewModel(for: order), coordinator: coordinator)
            Text("Order")
        case .inventoryDetail(let inventoryItem):
            //            InventoryDetailView(viewModel: dependencies.provideInventoryDetailViewModel(for: inventoryItem), coordinator: coordinator)
            Text("Inventory")
        }
    }
}

// MARK: - Preview Mocks for Unit Testing

//#if DEBUG
//// Mock dependencies for testing
//class MockDependencyContainer: DependencyContainer {
//    func provideHomeViewModel() -> HomeViewModel {
//        return HomeViewModel()
////        return HomeViewModel(orderService: MockOrderService())
//    }
//
//    func provideAuthenticationViewModel() -> AuthenticationViewModel {
//        return AuthenticationViewModel()
//    }

//    func provideOrderDetailViewModel(for order: Order) -> OrderDetailViewModel {
//        return OrderDetailViewModel(order: order, orderService: MockOrderService())
//    }
//
//    func provideInventoryDetailViewModel(for item: InventoryItem) -> InventoryDetailViewModel {
//        return InventoryDetailViewModel(item: item, inventoryService: MockInventoryService())
//    }
//}

//// Mock Coordinator for testing views in isolation
//class MockAppCoordinator: AppCoordinatorProtocol {
//    var navigationPath = NavigationPath()
//    var selectedTab: HomeTab = .menu
//    var loadingState: LoadingState = .idle
//
//    func navigateTo(_ destination: AppDestination, using presentationType: PresentationType) {
//        print("Navigate to \(destination) using \(presentationType)")
//    }
//
//    func navigateToRoot(_ destination: AppDestination) {
//        print("Navigate to root: \(destination)")
//    }
//
//    func navigateBack() {
//        print("Navigate back")
//    }
//
//    func popToLevel(_ level: Int) {
//        print("Pop to level \(level)")
//    }
//
//    func dismissSheet() {
//        print("Dismiss sheet")
//    }
//
//    func dismissCover() {
//        print("Dismiss cover")
//    }
//}
//
//// Example of how to set up tests
//struct AppCoordinatorTests {
//    static func testNavigationToDashboard() {
//        let dependencies = MockDependencyContainer()
//        let coordinator = AppCoordinator(dependencies: dependencies)
//
//        // Simulate navigation
//        coordinator.navigateTo(.home)
//
//        // Assert navigation occurred correctly
//        assert(coordinator.navigationPath.count == 1)
//    }
//}
//#endif
//
//#if DEBUG
//class MockAuthService: AuthServiceProtocol {
//    func login(email: String, password: String, completion: @escaping (Result<Void, AppError>) -> Void) {
//
//    }
//
//    func logout() {
//
//    }
//
//    func currentUser() -> SessionUser? {
//
//    }
//
//    func registerShopAccount(email: String, password: String, shopName: String, completion: @escaping (Result<Void, AppError>) -> Void) {
//
//    }
//}
//class MockOrderService: OrderServiceProtocol {
//    func createOrder(items: [OrderItem]) async throws -> Order {
//
//    }
//
//    func getOrders() async throws -> [Order] {
//
//    }
//
//    func getOrderDetails(id: String) async throws -> Order {
//
//    }
//}
//class MockInventoryService: InventoryServiceProtocol {
//    func getInventoryItems() async throws -> [InventoryItem] {
//
//    }
//
//    func getInventoryItem(id: String) async throws -> InventoryItem {
//
//    }
//
//    func updateInventoryItem(item: InventoryItem) async throws -> InventoryItem {
//
//    }
//
//    func addInventoryItem(item: InventoryItem) async throws -> InventoryItem {
//
//    }
//}
//#endif
