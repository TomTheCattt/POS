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
    
    // MARK: - Published Properties
    // Authentication
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var isOwnerAuthenticated: Bool?
    @Published private(set) var remainingTime: TimeInterval = 0
    
    // Shop Management
    @Published private(set) var shops: [Shop]?
    @Published private(set) var activatedShop: Shop?
    
    // Menu Management
    @Published private(set) var menuList: [AppMenu]?
    @Published private(set) var activatedMenu: AppMenu?
    @Published private(set) var menuItems: [MenuItem]?
    
    // Order Management
    @Published private(set) var orders: [Order]?
    
    // Inventory Management
    @Published private(set) var ingredients: [IngredientUsage]?
    
    // UI State
    @Published private(set) var isLoading = false
    @Published private(set) var loadingText: String?
    @Published private(set) var progress: Double?
    @Published private(set) var error: AppError?
    @Published private(set) var alert: AlertItem?
    @Published private(set) var toastMessage: (type: ToastType, message: String)?
    
    // MARK: - Persistence
    @AppStorage("userId") var userId: String = ""
    
    // MARK: - Combine
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication Properties
    private let authTimeoutInterval: TimeInterval = 3600
    private var authTimer: AnyCancellable?
    private var remainingTimer: AnyCancellable?
    
    // MARK: - Computed Properties
    var remainingTimeString: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Publishers
    // Authentication
    var currentUserPublisher: AnyPublisher<AppUser?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    var isOwnerAuthenticatedPublisher: AnyPublisher<Bool?, Never> {
        $isOwnerAuthenticated.eraseToAnyPublisher()
    }
    
    // Shop Management
    var currentShopsPublisher: AnyPublisher<[Shop]?, Never> {
        $shops.eraseToAnyPublisher()
    }
    
    var activatedShopPublisher: AnyPublisher<Shop?, Never> {
        $activatedShop.eraseToAnyPublisher()
    }
    
    // Menu Management
    var menuListPublisher: AnyPublisher<[AppMenu]?, Never> {
        $menuList.eraseToAnyPublisher()
    }
    
    var activatedMenuPublisher: AnyPublisher<AppMenu?, Never> {
        $activatedMenu.eraseToAnyPublisher()
    }
    
    var menuItemsPublisher: AnyPublisher<[MenuItem]?, Never> {
        $menuItems.eraseToAnyPublisher()
    }
    
    // Order Management
    var ordersPublisher: AnyPublisher<[Order]?, Never> {
        $orders.eraseToAnyPublisher()
    }
    
    // Inventory Management
    var ingredientsPublisher: AnyPublisher<[IngredientUsage]?, Never> {
        $ingredients.eraseToAnyPublisher()
    }
    
    // UI State
    var errorPublisher: AnyPublisher<AppError?, Never> {
        $error.eraseToAnyPublisher()
    }
    
    var loadingPublisher: AnyPublisher<(Bool, String?), Never> {
        Publishers.CombineLatest($isLoading, $loadingText)
            .eraseToAnyPublisher()
    }
    
    var loadingWithProgressPublisher: AnyPublisher<(Double?), Never> {
        $progress.eraseToAnyPublisher()
    }
    
    var toastPublisher: AnyPublisher<((type: ToastType, message: String)?), Never> {
        $toastMessage.eraseToAnyPublisher()
    }
    
    var alertPublisher: AnyPublisher<AlertItem?, Never> {
        $alert.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization & Cleanup
    init(environment: AppEnvironment = AppEnvironment()) {
        self.environment = environment
        setupAuthStateListener()
        setupInitialState()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            await self?.cleanupResources()
        }
    }
    
    // MARK: - Setup Methods
    private func setupInitialState() {
        Task {
            if !userId.isEmpty {
                await fetchStoredUserData()
            }
        }
    }
    
    private func setupAuthStateListener() {
        environment.authService.setupAuthStateListener { [weak self] state in
            Task { @MainActor [weak self] in
                switch state {
                case .authenticated:
                    if let user = self?.environment.authService.auth.currentUser {
                        await self?.handleAuthStateChange(user)
                    }
                case .unauthenticated:
                    await self?.handleSignOut()
                case .emailNotVerified:
                    await self?.handleEmailNotVerified()
                case .loading:
                    self?.isLoading = true
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    private func handleAuthStateChange(_ user: FirebaseAuth.User?) async {
        if let user = user {
            do {
                try await environment.authService.checkEmailVerification()
                
                if let userData: AppUser = try await environment.databaseService.getUser(userId: user.uid) {
                    await MainActor.run {
                        self.userId = userData.id!
                    }
                    await fetchShops(for: userId)
                    
                    await MainActor.run {
                        self.currentUser = userData
                    }
                }
            } catch let error as AppError {
                if case .auth(.unverifiedEmail) = error {
                    await MainActor.run {
                        self.userId = user.uid
                        self.currentUser = nil
                    }
                } else {
                    await handleSignOut()
                }
            } catch {
                await handleSignOut()
            }
        } else {
            await handleSignOut()
        }
    }
    
    private func handleEmailNotVerified() async {
        if let uid = environment.authService.auth.currentUser?.uid {
            userId = uid
        }
        currentUser = nil
        isLoading = false
    }
    
    private func handleSignOut() async {
        await MainActor.run {
            self.currentUser = nil
            self.isOwnerAuthenticated = false
            self.remainingTime = 0
        }
        invalidateAuthTimer()
        invalidateRemainingTimer()
        await removeAllListeners()
        
        await MainActor.run {
            self.userId = ""
        }
    }
    
    func signOut() async {
        do {
            try await environment.authService.signOut()
            await handleSignOut()
        } catch {
            handleError(error, action: "đăng xuất")
        }
    }
    
    // MARK: - Data Fetching Methods
    private func fetchStoredUserData() async {
        do {
            guard !userId.isEmpty else { return }
            
            if let userData: AppUser = try await environment.databaseService.getUser(userId: userId) {
                await fetchShops(for: userId)
                
                await MainActor.run {
                    self.currentUser = userData
                }
            }
        } catch {
            await MainActor.run {
                self.handleError(error, action: "tải dữ liệu người dùng")
                self.currentUser = nil
            }
        }
    }
    
    private func fetchShops(for user: String) async {
        do {
            let fetchedShops: [Shop] = try await environment.databaseService.getAllShops(userId: user)
            
            await MainActor.run {
                self.shops = fetchedShops
            }
            
            if let activatedShop = fetchedShops.first(where: { $0.isActive }) {
                await MainActor.run {
                    self.activatedShop = activatedShop
                }
                await fetchActivatedShop(activatedShop)
            }
        } catch {
            handleError(error, action: "tải danh sách cửa hàng")
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
    
    // MARK: - Shop Management Methods
    func switchShop(to newShop: Shop) async {
        guard let newShopId = newShop.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        guard newShop.isActive == false else { return }
        
        do {
            if let currentActiveShop = shops?.first(where: { $0.isActive && $0.id != newShopId }) {
                var updatedCurrent = currentActiveShop
                updatedCurrent.isActive = false
                
                let _ = try await environment.databaseService.updateShop(
                    updatedCurrent,
                    userId: userId,
                    shopId: updatedCurrent.id!
                )
            }
            
            var updatedNewShop = newShop
            updatedNewShop.isActive = true
            
            let _ = try await environment.databaseService.updateShop(
                updatedNewShop,
                userId: userId,
                shopId: updatedNewShop.id!
            )
            
            await fetchActivatedShop(updatedNewShop)
            activatedShop = updatedNewShop
            
        } catch {
            handleError(AppError.shop(.updateFailed))
        }
    }
    
    // MARK: - Menu Management Methods
    private func fetchShopMenu(shopId: String) async {
        do {
            let fetchedMenu: [AppMenu] = try await environment.databaseService.getAllMenu(userId: userId, shopId: shopId)
            let activeMenu = fetchedMenu.first(where: { $0.isActive })
            
            await MainActor.run {
                self.menuList = fetchedMenu
                self.activatedMenu = activeMenu
            }
            
            if let activeMenu = activeMenu {
                await fetchMenuItems(shopId: shopId, menuId: activeMenu.id)
            }
        } catch {
            handleError(error, action: "tải thực đơn")
        }
    }
    
    private func fetchMenuItems(shopId: String, menuId: String?) async {
        guard let menuId = menuId else { return }
        
        do {
            let items: [MenuItem] = try await environment.databaseService.getAllMenuItems(
                userId: userId,
                shopId: shopId,
                menuId: menuId
            )
            
            await MainActor.run {
                self.menuItems = items
            }
        } catch {
            handleError(error, action: "tải danh sách món")
        }
    }
    
    func activateMenu(_ menu: AppMenu) async {
        guard let shopId = activatedShop?.id,
              let menuId = menu.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        do {
            if let currentActiveMenu = self.menuList?.first(where: { $0.isActive && $0.id != menuId }) {
                var updatedCurrentMenu = currentActiveMenu
                updatedCurrentMenu.isActive = false
                let _ = try await environment.databaseService.updateMenu(
                    updatedCurrentMenu,
                    userId: userId,
                    shopId: shopId,
                    menuId: updatedCurrentMenu.id!
                )
            }
            
            var updatedMenu = menu
            updatedMenu.isActive = true
            let _ = try await environment.databaseService.updateMenu(
                updatedMenu,
                userId: userId,
                shopId: shopId,
                menuId: menuId
            )
            self.activatedMenu = updatedMenu
            showSuccess("Đã kích hoạt thực đơn \(menu.menuName)")
        } catch {
            handleError(error, action: "kích hoạt thực đơn")
        }
    }
    
    func deactivateMenu(_ menu: AppMenu) async {
        guard let shopId = activatedShop?.id,
              let menuId = menu.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        do {
            if let anotherMenu = self.menuList?.first(where: { $0.id != menuId }) {
                var updatedCurrentMenu = menu
                updatedCurrentMenu.isActive = false
                let _ = try await environment.databaseService.updateMenu(
                    updatedCurrentMenu,
                    userId: userId,
                    shopId: shopId,
                    menuId: updatedCurrentMenu.id!
                )
                
                await activateMenu(anotherMenu)
            } else {
                showError("Không thể tắt thực đơn duy nhất")
            }
        } catch {
            handleError(error, action: "tắt thực đơn")
        }
    }
    
    // MARK: - Order Management Methods
    private func fetchShopOrders(shopId: String) async {
        do {
            orders = try await environment.databaseService.getAllOrders(userId: userId, shopId: shopId)
        } catch {
            handleError(error, action: "tải đơn hàng")
        }
    }
    
    // MARK: - Inventory Management Methods
    private func fetchShopIngredients(shopId: String) async {
        do {
            ingredients = try await environment.databaseService.getAllIngredientUsages(userId: userId, shopId: shopId)
        } catch {
            handleError(error, action: "tải nguyên liệu")
        }
    }
    
    // MARK: - Listener Management
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
    
    func setupMenuListListener(shopId: String) {
        environment.databaseService.listenToMenuCollection(
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
        environment.databaseService.removeMenuCollectionListener(userId: userId, shopId: shopId)
    }
    
    func setupOrdersListener(shopId: String) {
        
        environment.databaseService.listenToOrders(
            userId: userId,
            shopId: shopId,
            queryBuilder: nil
        ) { [weak self] (result: Result<[Order], Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let orders):
                    self.orders = orders
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi đơn hàng")
                }
            }
        }
    }
    
    func removeOrdersListener(shopId: String) {
        environment.databaseService.removeOrdersListener(userId: userId, shopId: shopId)
    }
    
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
    
    func setupMenuItemsListener(shopId: String, menuId: String?) {
        
        guard let activatedMenu, let activatedMenuId = activatedMenu.id else {
            return
        }
        
        environment.databaseService.listenToMenuItems(
            userId: userId,
            shopId: shopId,
            menuId: menuId ?? activatedMenuId,
            queryBuilder: nil
        ) { [weak self] (result: Result<[MenuItem], Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let menuItems):
                    self.menuItems = menuItems
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi sản phẩm trong thực đơn")
                }
            }
        }
    }
    
    func removeMenuItemsListener(shopId: String, menuId: String?) {
        guard let activatedMenu, let activatedMenuId = activatedMenu.id else {
            return
        }
        environment.databaseService.removeMenuItemsListener(shopId: shopId, menuId: menuId ?? activatedMenuId)
    }
    
    private func removeAllListeners() async {
        let listenerKeys = [
            "user_\(userId)",
            "shop_\(activatedShop?.id ?? "")",
            "orders_\(activatedShop?.id ?? "")",
            "menu_\(activatedShop?.id ?? "")",
            "inventory_\(activatedShop?.id ?? "")",
            "ingredients_\(activatedShop?.id ?? "")"
        ]
        
        listenerKeys.forEach { key in
            environment.databaseService.removeListener(forKey: key)
        }
    }
    
    private func cleanupResources() async {
        environment.authService.removeAuthStateListener()
        await removeAllListeners()
        cancellables.removeAll()
        invalidateAuthTimer()
        invalidateRemainingTimer()
        await resetState()
    }
    
    // MARK: - UI State Management
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
    
    // MARK: - Toast & Alert Methods
    func showError(_ message: String, autoHide: Bool = true) {
        toastMessage = (.error, message)
    }
    
    func showSuccess(_ message: String, autoHide: Bool = true) {
        toastMessage = (.success, message)
    }
    
    func showInfo(_ message: String, autoHide: Bool = true) {
        toastMessage = (.info, message)
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
    
    // MARK: - State Management
    private func resetState() async {
        currentUser = nil
        orders = nil
        menuList = nil
        ingredients = nil
        error = nil
        alert = nil
        isLoading = false
        loadingText = nil
        progress = nil
        toastMessage = nil
        isOwnerAuthenticated = false
        remainingTime = 0
        await removeAllListeners()
    }
    
    // MARK: - Owner Authentication Methods
    func authenticateAsOwner(password: String) -> Bool {
        guard password == currentUser?.ownerPassword else {
            return false
        }
        
        isOwnerAuthenticated = true
        startAuthTimer()
        startRemainingTimer()
        remainingTime = authTimeoutInterval
        return true
    }
    
    func logoutAsOwner() {
        isOwnerAuthenticated = false
        invalidateAuthTimer()
        invalidateRemainingTimer()
        remainingTime = 0
    }
    
    private func startAuthTimer() {
        invalidateAuthTimer()
        authTimer = Timer.publish(every: authTimeoutInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.logoutAsOwner()
                }
            }
    }
    
    private func startRemainingTimer() {
        invalidateRemainingTimer()
        remainingTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                }
            }
    }
    
    private func invalidateAuthTimer() {
        authTimer?.cancel()
        authTimer = nil
    }
    
    private func invalidateRemainingTimer() {
        remainingTimer?.cancel()
        remainingTimer = nil
    }
}

// MARK: - Supporting Types
struct AlertItem {
    let title: String
    let message: String?
    var primaryButton: AlertButton?
    var secondaryButton: AlertButton?
}

struct AlertButton {
    let title: String
    var role: ButtonRole = .cancel
    var action: (() -> Void)?
}
