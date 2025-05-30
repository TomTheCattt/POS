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
    /// Currently selected shop
    @Published private(set) var selectedShop: Shop?
    /// Currently selected shop's orders
    @Published private(set) var orders: [Order]?
    /// Currently selected shop's menu
    @Published private(set) var menu: [MenuItem]?
    /// Currently selected shop's inventory
    @Published private(set) var inventory: [InventoryItem]?
    /// Currently selected shop's ingredients usage
    @Published private(set) var ingredients: [IngredientUsage]?

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
    /// Persisted selected shop ID
    @AppStorage("selectedShopId") private var selectedShopId: String?

    // MARK: - Environment & Services
    /// Set of cancellables for managing Combine subscriptions
    var cancellables = Set<AnyCancellable>()

    // MARK: - Listeners
    /// Firebase Auth state listener
    private var authStateListener: AuthStateDidChangeListenerHandle?
    /// Firestore user document listener
    private var userListener: ListenerRegistration?
    /// Firestore shop document listener
    private var shopListener: ListenerRegistration?
    /// Firestore order document listener
    private var ordersListener: ListenerRegistration?
    /// Firestore menu document listener
    private var menuListener: ListenerRegistration?
    /// Firestore inventory document listener
    private var inventoryListener: ListenerRegistration?
    /// Firestore ingredients document listener
    private var ingredientsListener: ListenerRegistration?
    /// Collection of active Firestore listeners
    private var listeners: [ListenerRegistration] = []

    // MARK: - Publishers
    /// Publisher for current user changes
    var currentUserSubject: CurrentValueSubject<AppUser?, Never> = CurrentValueSubject(nil)
    
    /// Publisher for current user changes
    var currentUserPublisher: AnyPublisher<AppUser?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    /// Publisher for selected shop changes
    var selectedShopPublisher: AnyPublisher<Shop?, Never> {
        $selectedShop.eraseToAnyPublisher()
    }
    
    /// Publisher for selected shop's orders changes
    var ordersPublisher: AnyPublisher<[Order]?, Never> {
        $orders.eraseToAnyPublisher()
    }
    
    /// Publisher for selected shop's menu changes
    var menuPublisher: AnyPublisher<[MenuItem]?, Never> {
        $menu.eraseToAnyPublisher()
    }
    
    /// Publisher for selected shop's inventory changes
    var inventoryPublisher: AnyPublisher<[InventoryItem]?, Never> {
        $inventory.eraseToAnyPublisher()
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
        // Remove individual listeners
        if let userListener = userListener {
            environment.databaseService.removeListener(forKey: userListener.description)
        }
        userListener = nil
        
        if let shopListener = shopListener {
            environment.databaseService.removeListener(forKey: shopListener.description)
        }
        shopListener = nil
        
        if let ordersListener = ordersListener {
            environment.databaseService.removeListener(forKey: ordersListener.description)
        }
        ordersListener = nil
        
        if let menuListener = menuListener {
            environment.databaseService.removeListener(forKey: menuListener.description)
        }
        menuListener = nil
        
        if let inventoryListener = inventoryListener {
            environment.databaseService.removeListener(forKey: inventoryListener.description)
        }
        inventoryListener = nil
        
        if let ingredientsListener = ingredientsListener {
            environment.databaseService.removeListener(forKey: ingredientsListener.description)
        }
        ingredientsListener = nil
        
        // Remove all remaining listeners
        listeners.forEach { listener in
            environment.databaseService.removeListener(forKey: listener.description)
        }
        listeners.removeAll()
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
                }
                await fetchAndSetupShop()
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

    private func fetchAndSetupShop() async {
        do {
            let shops: [Shop] = try await environment.databaseService.getAllShops(userId: userId)
            
            if let storedShopId = selectedShopId {
                if let shop = shops.first(where: { $0.id == storedShopId }) {
                    await selectShop(shop)
                } else {
                    await selectFirstShop(from: shops)
                }
            } else {
                await selectFirstShop(from: shops)
            }
        } catch {
            handleError(error, action: "tải danh sách cửa hàng")
        }
    }

    private func selectFirstShop(from shops: [Shop]) async {
        if let firstShop = shops.first {
            await selectShop(firstShop)
        }
    }

    func selectShop(_ shop: Shop) async {
        guard let shopId = shop.id else {
            handleError(AppError.shop(.notFound))
            return
        }

        selectedShop = shop
        selectedShopId = shopId

        setupShopListener(shopId: shopId)
        setupMenuListener(shopId: shopId)
        setupOrdersListener(shopId: shopId)
        setupInventoryListener(shopId: shopId)
        setupIngredientsListener(shopId: shopId)
    }
    
    func refreshAuthListener() {
        guard let authStateListener else { return }
        environment.authService.auth.removeStateDidChangeListener(authStateListener)
        setupAuthStateListener()
    }

    // MARK: - Auth State Handling
    private func handleAuthStateChange(_ user: FirebaseAuth.User?) async {
        if let user = user {
            do {
                try await environment.authService.checkEmailVerification()
                
                if let userData: AppUser = try await environment.databaseService.getUser(userId: user.uid) {
                    await MainActor.run {
                        self.currentUser = userData
                        self.userId = user.uid
                    }
                    
                    await setupUserListener(userId: userData.id ?? "")
                    await fetchAndSetupShop()
                } else {
                    await MainActor.run {
                        self.currentUser = nil
                        self.userId = ""
                        self.selectedShopId = nil
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
                        self.selectedShopId = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.userId = ""
                    self.selectedShopId = nil
                }
            }
        } else {
            await MainActor.run {
                self.currentUser = nil
                self.userId = ""
                self.selectedShopId = nil
            }
        }
    }

    // MARK: - User & Shop Listeners
    private func setupUserListener(userId: String) async {
        // Remove existing listener
        if let userListener = userListener {
            environment.databaseService.removeListener(forKey: userListener.description)
        }
        userListener = nil
        
        userListener = environment.databaseService.addDocumentListener(
            collection: .users,
            type: .collection,
            id: userId
        ) { [weak self] (result: Result<AppUser?, Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let user):
                    guard let user = user, let id = user.id else {
                        self.handleError(AppError.auth(.userNotFound))
                        return
                    }
                    
                    self.currentUser = user
                    self.userId = id
                    await self.fetchAndSetupShop()
                    
                case .failure(let error):
                    self.handleError(error, action: "tải thông tin người dùng")
                }
            }
        }
        
        if let listener = userListener {
            addToListeners(listener)
        }
    }
    
    private func setupShopListener(shopId: String) {
        if let shopListener = shopListener {
            environment.databaseService.removeListener(forKey: shopListener.description)
        }
        shopListener = nil
        
        shopListener = environment.databaseService.addDocumentListener(
            collection: .shops,
            type: .subcollection(parentId: userId),
            id: shopId
        ) { [weak self] (result: Result<Shop?, Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let shop):
                    guard let shop = shop else {
                        self.handleError(AppError.shop(.notFound))
                        return
                    }
                    
                    self.selectedShop = shop
                    self.selectedShopId = shop.id
                    
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi cửa hàng")
                }
            }
        }
        
        if let listener = shopListener {
            addToListeners(listener)
        }
    }
    
    private func setupMenuListener(shopId: String) {
        if let menuListener = menuListener {
            environment.databaseService.removeListener(forKey: menuListener.description)
        }
        menuListener = nil
        
        menuListener = environment.databaseService.addListener(
            collection: .menu,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: nil
        ) { [weak self] (result: Result<[MenuItem], Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let menu):
                    self.menu = menu
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi của thực đơn")
                }
            }
        }
        
        if let listener = menuListener {
            addToListeners(listener)
        }
    }
    
    private func setupOrdersListener(shopId: String) {
        if let ordersListener = ordersListener {
            environment.databaseService.removeListener(forKey: ordersListener.description)
        }
        ordersListener = nil
        
        ordersListener = environment.databaseService.addListener(
            collection: .orders,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
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
        
        if let listener = ordersListener {
            addToListeners(listener)
        }
    }
    
    private func setupInventoryListener(shopId: String) {
        if let inventoryListener = inventoryListener {
            environment.databaseService.removeListener(forKey: inventoryListener.description)
        }
        inventoryListener = nil
        
        inventoryListener = environment.databaseService.addListener(
            collection: .inventory,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: nil
        ) { [weak self] (result: Result<[InventoryItem], Error>) in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let inventory):
                    self.inventory = inventory
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi kho")
                }
            }
        }
        
        if let listener = inventoryListener {
            addToListeners(listener)
        }
    }
    
    private func setupIngredientsListener(shopId: String) {
        if let ingredientsListener = ingredientsListener {
            environment.databaseService.removeListener(forKey: ingredientsListener.description)
        }
        ingredientsListener = nil
        
        ingredientsListener = environment.databaseService.addListener(
            collection: .ingredientsUsage,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: nil
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
        
        if let listener = ingredientsListener {
            addToListeners(listener)
        }
    }

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
    func addToListeners(_ listener: ListenerRegistration) {
        listeners.append(listener)
    }
    
    func resetState() async {
        currentUser = nil
        selectedShop = nil
        orders = nil
        menu = nil
        inventory = nil
        ingredients = nil
        error = nil
        alert = nil
        userId = ""
        selectedShopId = nil
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
