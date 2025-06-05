import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseCrashlytics

/// Base view model class providing common functionality for all view models
/// Implements authentication, loading, error handling, and real-time data synchronization
@MainActor
class SourceModel: ObservableObject {

    // MARK: - Dependencies
    let environment: AppEnvironment
    
    // MARK: - App State
    /// Current authenticated user
    @Published private(set) var currentUser: AppUser?
    /// Current shops
    @Published private(set) var shops: [Shop]?
    /// Current activated shops
    @Published private(set) var activatedShop: Shop?
    /// Currently selected shop's orders
    @Published private(set) var orders: [Order]?
    /// Currently selected shop's ingredients usage
    @Published private(set) var ingredients: [IngredientUsage]?
    /// Currently shop's menu
    @Published private(set) var menuList: [AppMenu]?
    /// Current activated menu
    @Published private(set) var activatedMenu: AppMenu?

    // MARK: - UI State
    /// Loading state indicator
    @Published var isLoading = false
    /// Loading message to display
    @Published var loadingText: String?
    /// Progress value for progress-based operations (0.0 to 1.0)
    @Published var progress: Double?
    /// Current error state
    @Published var error: AppError?
    /// Current alert to display
    @Published var alert: AlertItem?
    /// Toast message to display
    @Published var toastMessage: (type: ToastType, message: String)?
    /// Show toast state
    @Published var showToast = false
    /// Error message to display
    @Published var errorMessage: String?
    /// Success message to display
    @Published var successMessage: String?

    // MARK: - Persistence
    @AppStorage("userId") var userId: String = ""

    // MARK: - Environment & Services
    /// Set of cancellables for managing Combine subscriptions
    var cancellables = Set<AnyCancellable>()

    // MARK: - Listeners
    /// Firebase Auth state listener
    private var authStateListener: AuthStateDidChangeListenerHandle?

    // MARK: - Publishers
    /// Publisher for current user changes
    
    /// Publisher for current user changes
    var currentUserPublisher: AnyPublisher<AppUser?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    /// Publisher for shops changes
    var currentShopsPublisher: AnyPublisher<[Shop]?, Never> {
        $shops.eraseToAnyPublisher()
    }
    
    /// Publisher for shops changes
    var activatedShopPublisher: AnyPublisher<Shop?, Never> {
        $activatedShop.eraseToAnyPublisher()
    }
    
    /// Publisher for orders changes
    var ordersPublisher: AnyPublisher<[Order]?, Never> {
        $orders.eraseToAnyPublisher()
    }
    
    /// Publisher for menu list changes
    var menuListPublisher: AnyPublisher<[AppMenu]?, Never> {
        $menuList.eraseToAnyPublisher()
    }
    
    /// Publisher for menu changes
    var activatedMenuPublisher: AnyPublisher<AppMenu?, Never> {
        $activatedMenu.eraseToAnyPublisher()
    }
    
    /// Publisher for selected shop's ingredients changes
    var ingredientsPublisher: AnyPublisher<[IngredientUsage]?, Never> {
        $ingredients.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<AppError?, Never> {
        $error.eraseToAnyPublisher()
    }

    var loadingPublisher: AnyPublisher<(Bool, String?), Never> {
        Publishers.CombineLatest($isLoading, $loadingText)
            .eraseToAnyPublisher()
    }

    // MARK: - Initialization
    init(environment: AppEnvironment = AppEnvironment()) {
        self.environment = environment
        setupAuthStateListener()
        setupInitialState()
    }

    deinit {
        // Chuyển cleanup sang nonisolated context
        Task { @MainActor [weak self] in
            await self?.cleanupResources()
        }
    }
    
    // MARK: - Resource Management
    private func cleanupResources() async {
        // Remove auth state listener
        environment.authService.removeAuthStateListener()
        
        // Remove all Firestore listeners
        await removeAllListeners()
        
        // Cancel all subscriptions
        cancellables.removeAll()
        
        // Reset state
        await resetState()
    }
    
    private func removeAllListeners() async {
        let listenerKeys = [
            "user_\(userId)",
            "shop_\(activatedShop!.id ?? "")",
            "orders_\(activatedShop!.id ?? "")",
            "menu_\(activatedShop!.id ?? "")",
            "inventory_\(activatedShop!.id ?? "")",
            "ingredients_\(activatedShop!.id ?? "")"
        ]
        
        listenerKeys.forEach { key in
            environment.databaseService.removeListener(forKey: key)
        }
    }

    // MARK: - Setup Methods
    private func setupAuthStateListener() {
        environment.authService.setupAuthStateListener { [weak self] state in
            Task { @MainActor [weak self] in
                switch state {
                case .authenticated:
                    if let user = self?.environment.authService.auth.currentUser {
                        await self?.handleAuthStateChange(user)
                    }
                case .unauthenticated:
                    await self?.handleAuthStateChange(nil)
                case .emailNotVerified:
                    await self?.handleEmailNotVerified()
                case .loading:
                    self?.isLoading = true
                }
            }
        }
    }
    
    private func handleEmailNotVerified() async {
        currentUser = nil
        if let uid = environment.authService.auth.currentUser?.uid {
            userId = uid
        }
        isLoading = false
    }
    
    private func setupInitialState() {
        Task {
            await fetchStoredUserData()
        }
    }

    private func fetchStoredUserData() async {
        do {
            guard !userId.isEmpty else {
                await MainActor.run {
                    self.currentUser = nil
                }
                return
            }
            
            if let userData: AppUser = try await environment.databaseService.getUser(userId: userId) {
                await MainActor.run {
                    self.currentUser = userData
                    self.userId = userData.id!
                }
                await fetchShops()
            } else {
                await MainActor.run {
                    self.currentUser = nil
                    self.userId = ""
                }
            }
        } catch {
            await MainActor.run {
                self.handleError(error, action: "tải dữ liệu người dùng")
                self.currentUser = nil
                self.userId = ""
            }
        }
    }

    private func fetchShops() async {
        do {
            shops = try await environment.databaseService.getAllShops(userId: userId)
            if let activatedShop = shops?.first(where: { $0.isActive }) {
                self.activatedShop = activatedShop
                await fetchActivatedShop(activatedShop)
            }
        } catch {
            handleError(error, action: "tải danh sách cửa hàng")
        }
    }
    
    private func fetchShopIngredients(shopId: String) async {
        do {
            ingredients = try await environment.databaseService.getAllIngredientUsages(userId: userId, shopId: shopId)
        } catch {
            handleError(error, action: "tải nguyên liệu")
        }
    }
    
    private func fetchShopOrders(shopId: String) async {
        do {
            orders = try await environment.databaseService.getAllOrders(userId: userId, shopId: shopId)
        } catch {
            handleError(error, action: "tải đơn hàng")
        }
    }
    
    private func fetchShopMenu(shopId: String) async {
        do {
            menuList = try await environment.databaseService.getAllMenu(userId: userId, shopId: shopId)
            activatedMenu = menuList?.first(where: { $0.isActive })
        } catch {
            handleError(error, action: "tải thực đơn")
        }
    }
    
    func activateShop(_ shop: Shop) async {
        guard let shopId = shop.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        if let currentActiveShop = shops?.first(where: { $0.isActive && $0.id != shopId }) {
            do {
                var updateCurrentActiveShop = currentActiveShop
                updateCurrentActiveShop.isActive = false
                updateCurrentActiveShop.updatedAt = Date()
                let _ = try await environment.databaseService.updateShop(updateCurrentActiveShop, userId: userId, shopId: updateCurrentActiveShop.id!)
                
                var updateShop = shop
                updateShop.isActive = true
                updateShop.updatedAt = Date()
                let _ = try await environment.databaseService.updateShop(updateShop, userId: userId, shopId: updateShop.id!)
                await fetchActivatedShop(updateShop)
            } catch {
                handleError(AppError.shop(.updateFailed))
            }
        }
    }
    
    func deactivateShop(_ shop: Shop) async {
        guard let shopId = shop.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        do {
            if let anotherShop = self.shops?.first(where: { $0.id != shopId }) {
                var updatedCurrentShop = shop
                updatedCurrentShop.isActive = false
                updatedCurrentShop.updatedAt = Date()
                let _ = try await environment.databaseService.updateShop(updatedCurrentShop, userId: userId, shopId: updatedCurrentShop.id!)
                
                await activateShop(anotherShop)
            } else {
                showError("Không thể tắt cửa hàng duy nhất")
            }
        } catch {
            handleError(error, action: "tắt cửa hàng")
        }
    }

    private func fetchActivatedShop(_ shop: Shop) async {
        guard let shopId = shop.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        await fetchShopMenu(shopId: shopId)
        await fetchShopOrders(shopId: shopId)
        await fetchShopIngredients(shopId: shopId)
    }
    
    func activateMenu(_ menu: AppMenu) async {
        guard let shopId = activatedShop!.id,
              let menuId = menu.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        do {
            // Deactivate current active menu if exists
            if let currentActiveMenu = self.menuList?.first(where: { $0.isActive && $0.id != menuId }) {
                var updatedCurrentMenu = currentActiveMenu
                updatedCurrentMenu.isActive = false
                updatedCurrentMenu.updatedAt = Date()
                let _ = try await environment.databaseService.updateMenu(
                    updatedCurrentMenu,
                    userId: userId,
                    shopId: shopId,
                    menuId: updatedCurrentMenu.id!
                )
            }
            
            // Activate new menu
            var updatedMenu = menu
            updatedMenu.isActive = true
            updatedMenu.updatedAt = Date()
            let _ = try await environment.databaseService.updateMenu(
                updatedMenu,
                userId: userId,
                shopId: shopId,
                menuId: menuId
            )
            
            showSuccess("Đã kích hoạt thực đơn \(menu.menuName)")
        } catch {
            handleError(error, action: "kích hoạt thực đơn")
        }
    }
    
    func deactivateMenu(_ menu: AppMenu) async {
        guard let shopId = activatedShop!.id,
              let menuId = menu.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        do {
            // Only allow deactivate if there's another menu to activate
            if let anotherMenu = self.menuList?.first(where: { $0.id != menuId }) {
                // Deactivate current menu
                var updatedCurrentMenu = menu
                updatedCurrentMenu.isActive = false
                updatedCurrentMenu.updatedAt = Date()
                let _ = try await environment.databaseService.updateMenu(
                    updatedCurrentMenu,
                    userId: userId,
                    shopId: shopId,
                    menuId: updatedCurrentMenu.id!
                )
                
                // Activate another menu
                await activateMenu(anotherMenu)
            } else {
                showError("Không thể tắt thực đơn duy nhất")
            }
        } catch {
            handleError(error, action: "tắt thực đơn")
        }
    }
    
    // MARK: - Auth State Handling
    private func handleAuthStateChange(_ user: FirebaseAuth.User?) async {
        if let user = user {
            do {
                try await environment.authService.checkEmailVerification()
                
                if let userData: AppUser = try await environment.databaseService.getUser(userId: user.uid) {
                    await MainActor.run {
                        self.currentUser = userData
                        self.userId = userData.id!
                    }
                    await fetchShops()
                } else {
                    await MainActor.run {
                        self.currentUser = nil
                        self.userId = ""
                    }
                }
            } catch let error as AppError {
                if case .auth(.unverifiedEmail) = error {
                    await MainActor.run {
                        self.currentUser = nil
                        self.userId = user.uid
                    }
                } else {
                    await MainActor.run {
                        self.currentUser = nil
                        self.userId = ""
                    }
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.userId = ""
                }
            }
        } else {
            await MainActor.run {
                self.currentUser = nil
                self.userId = ""
            }
        }
    }

    // MARK: - User & Shop Listeners
//    private func setupUserListener(userId: String) {
//        environment.databaseService.listenToCurrentUser(userId: userId, completion: { [weak self] (result: Result<AppUser?, Error>) in
//            guard let self = self else { return }
//            
//            Task { @MainActor in
//                switch result {
//                case .success(let user):
//                    guard let user = user, let id = user.id else {
//                        self.handleError(AppError.auth(.userNotFound))
//                        return
//                    }
//                    
//                    self.currentUser = user
//                    self.userId = id
//                    await self.fetchShops()
//                    
//                case .failure(let error):
//                    self.handleError(error, action: "tải thông tin người dùng")
//                }
//            }
//        })
//    }
//    
    private func setupShopsListener() {
        environment.databaseService.listenToShops(userId: userId, queryBuilder: nil, completion: { [weak self] (result: Result<[Shop], Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let shops):
                    self.shops = shops
                    
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi cửa hàng")
                }
            }
        })
    }
//
    func setupMenuListListener(shopId: String) {
        environment.databaseService.listenToMenu(
            userId: userId,
            shopId: shopId,
            queryBuilder: { $0.order(by: "createdAt", descending: false) }
        ) { [weak self] (result: Result<[AppMenu], Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let menu):
                    self.menuList = menu
                    
                    // Nếu chưa có menu nào được chọn hoặc menu đang chọn không còn active
                    if self.activatedMenu == nil ||
                        (self.activatedMenu?.isActive == false && menu.contains(where: { $0.isActive })) {
                        if let activeMenu = menu.first(where: { $0.isActive }) {
                            self.activatedMenu = activeMenu
                        }
                    }
                    
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi của thực đơn")
                }
            }
        }
    }
    
    func removeMenuListListener(shopId: String) {
        environment.databaseService.removeMenuListener(userId: userId, shopId: shopId)
    }
//
//    private func setupOrdersListener(shopId: String) {
//        
//        environment.databaseService.listenToOrders(
//            userId: userId,
//            shopId: shopId,
//            queryBuilder: nil
//        ) { [weak self] (result: Result<[Order], Error>) in
//            guard let self = self else { return }
//            
//            Task { @MainActor in
//                switch result {
//                case .success(let orders):
//                    self.orders = orders
//                case .failure(let error):
//                    self.handleError(error, action: "lắng nghe thay đổi đơn hàng")
//                }
//            }
//        }
//    }
    
    func setupIngredientsListener(shopId: String) {
        
        environment.databaseService.listenToIngredients(
            userId: userId,
            shopId: shopId,
            queryBuilder: { $0.order(by: "name", descending: false) }
        ) { [weak self] (result: Result<[IngredientUsage], Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let ingredients):
                    self.ingredients = ingredients
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi nguyên liệu")
                }
            }
        }
    }
    
    func removeIngredientsListener(shopId: String) {
        environment.databaseService.removeIngredientsListener(userId: userId, shopId: shopId)
    }
    
//    private func setupMenuItemsListener(shopId: String, menuId: String) {
//        
//        environment.databaseService.listenToMenuItems(
//            userId: userId,
//            shopId: shopId,
//            menuId: menuId,
//            queryBuilder: nil
//        ) { [weak self] (result: Result<[MenuItem], Error>) in
//            guard let self = self else { return }
//            
//            Task { @MainActor in
//                switch result {
//                case .success(let menuItems):
//                case .failure(let error):
//                    self.handleError(error, action: "lắng nghe thay đổi sản phẩm trong thực đơn")
//                }
//            }
//        }
//    }

    // MARK: - Loading State Management
    func withLoading<T>(_ text: String? = nil, operation: () async throws -> T) async throws -> T {
        await MainActor.run { [weak self] in
            self?.isLoading = true
            self?.loadingText = text
        }
        
        defer {
            Task { @MainActor [weak self] in
                self?.isLoading = false
                self?.loadingText = nil
            }
        }
        
        return try await operation()
    }
    
    func withProgress<T>(_ operation: (@escaping (Double) -> Void) async throws -> T) async throws -> T {
        await MainActor.run { [weak self] in 
            self?.isLoading = true 
        }
        
        defer {
            Task { @MainActor [weak self] in
                self?.isLoading = false
                self?.progress = nil
            }
        }
        
        return try await operation { [weak self] value in
            Task { @MainActor in 
                self?.progress = value 
            }
        }
    }
    
    @ViewBuilder
    func loadingOverlay() -> some View {
        if isLoading {
            LoadingView(message: loadingText)
        }
    }

    // MARK: - Toast Methods
    func showError(_ message: String, autoHide: Bool = true) {
        toastMessage = (.error, message)
        showToast = true
        
        if autoHide {
            hideToastAfterDelay()
        }
    }
    
    func showSuccess(_ message: String, autoHide: Bool = true) {
        toastMessage = (.success, message)
        showToast = true
        
        if autoHide {
            hideToastAfterDelay()
        }
    }
    
    func showInfo(_ message: String, autoHide: Bool = true) {
        toastMessage = (.info, message)
        showToast = true
        
        if autoHide {
            hideToastAfterDelay()
        }
    }
    
    private func hideToastAfterDelay() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            withAnimation(.spring()) {
                self?.showToast = false
            }
        }
    }

    // MARK: - Error Handling
    func handleError(_ error: Error, action: String? = nil, completion: (() -> Void)? = nil) {
        environment.crashlyticsService.log(action ?? "Không xác định")
        
        if let appError = error as? AppError {
            self.error = appError
            showError(appError.localizedDescription)
        } else {
            self.error = AppError.unknown
            showError(error.localizedDescription)
        }
        
        if let action = action {
            showError("Lỗi khi \(action): \(error.localizedDescription)")
        }
    }
    
    func showAlert(title: String, message: String, primaryButton: AlertButton? = nil) {
        alert = AlertItem(title: title, message: message, primaryButton: primaryButton)
    }
    
    func showConfirmation(title: String, message: String, confirmAction: @escaping () -> Void) {
        alert = AlertItem(
            title: title,
            message: message,
            primaryButton: AlertButton(title: "Xác nhận", role: .destructive, action: confirmAction),
            secondaryButton: AlertButton(title: "Hủy", role: .cancel)
        )
    }

    // MARK: - State Management
    func resetState() async {
        currentUser = nil
        orders = nil
        menuList = nil
        ingredients = nil
        error = nil
        alert = nil
        userId = ""
        await removeAllListeners()
    }
    
    func addSubscription(_ subscription: AnyCancellable) {
        subscription.store(in: &cancellables)
    }
}

// MARK: - Alert Types
struct AlertItem {
    let title: String
    let message: String
    var primaryButton: AlertButton?
    var secondaryButton: AlertButton?
}

struct AlertButton {
    let title: String
    var role: AlertButtonRole = .default
    var action: (() -> Void)?
    
    enum AlertButtonRole {
        case `default`
        case cancel
        case destructive
    }
}
