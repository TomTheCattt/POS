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
    @Published private(set) var inventory: [InventoryItem]? {
        didSet {
            print(inventory)
        }
    }
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
//        currentUserSubject
//            .sink { user in
//                self.currentUser = user
//            }
//            .store(in: &cancellables)
//        currentUserSubject.assign(to: &$currentUser)
    }

    deinit {
        if let listener = authStateListener {
            environment.authService.auth.removeStateDidChangeListener(listener)
        }
        cancellables.removeAll()
        listeners.removeAll()
    }

    // MARK: - Setup Methods
    private func setupAuthStateListener() {
        authStateListener = environment.authService.auth.addStateDidChangeListener { [weak self] _, user in
            Task { [weak self] in
                await self?.handleAuthStateChange(user)
            }
        }
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
        userListener = environment.databaseService.addDocumentListener(
            collection: .users,
            type: .collection,
            id: userId
        ) { [weak self] (result: Result<AppUser?, Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                guard let user = user, let id = user.id else {
                    self.handleError(AppError.auth(.userNotFound))
                    return
                }
                self.currentUser = user
                self.userId = id
                
                Task {
                    await self.fetchAndSetupShop()
                }
                
            case .failure(let error):
                self.handleError(error, action: "tải thông tin người dùng")
            }
        }
        
        if let listener = userListener {
            addToListeners(listener)
        }
    }
    
    private func setupShopListener(shopId: String) {
        shopListener?.remove()
        
        shopListener = environment.databaseService.addDocumentListener(
            collection: .shops,
            type: .subcollection(parentId: userId),
            id: shopId
        ) { [weak self] (result: Result<Shop?, Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let shop):
                guard let shop = shop else {
                    self.handleError(AppError.shop(.notFound))
                    return
                }
                
                Task { @MainActor in
                    self.selectedShop = shop
                    self.selectedShopId = shop.id
                }
                
            case .failure(let error):
                self.handleError(error, action: "lắng nghe thay đổi cửa hàng")
            }
        }
        
        if let listener = shopListener {
            addToListeners(listener)
        }
    }
    
    private func setupMenuListener(shopId: String) {
        menuListener?.remove()
        
        menuListener = environment.databaseService.addListener(
            collection: .menu,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: nil
        ) { [weak self] (result: Result<[MenuItem], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let menu):
                
                Task { @MainActor in
                    self.menu = menu
                }
                
            case .failure(let error):
                self.handleError(error, action: "lắng nghe thay đổi của thực đơn")
            }
        }
        
        if let listener = menuListener {
            addToListeners(listener)
        }
    }
    
    private func setupOrdersListener(shopId: String) {
        ordersListener?.remove()
        
        ordersListener = environment.databaseService.addListener(
            collection: .orders,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: nil
        ) { [weak self] (result: Result<[Order], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let order):
                
                Task { @MainActor in
                    self.orders = order
                }
                
            case .failure(let error):
                self.handleError(error, action: "lắng nghe thay đổi đơn hàng")
            }
        }
        
        if let listener = ordersListener {
            addToListeners(listener)
        }
    }
    
    private func setupInventoryListener(shopId: String) {
        inventoryListener?.remove()
        
        inventoryListener = environment.databaseService.addListener(
            collection: .inventory,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: nil
        ) { [weak self] (result: Result<[InventoryItem], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let inventory):
                
                Task { @MainActor in
                    self.inventory = inventory
                }
                
            case .failure(let error):
                self.handleError(error, action: "lắng nghe thay đổi kho")
            }
        }
        
        if let listener = inventoryListener {
            addToListeners(listener)
        }
    }
    
    private func setupIngredientsListener(shopId: String) {
        ingredientsListener?.remove()
        
        ingredientsListener = environment.databaseService.addListener(
            collection: .ingredientsUsage,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: nil
        ) { [weak self] (result: Result<[IngredientUsage], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let ingredients):
                
                Task { @MainActor in
                    self.ingredients = ingredients
                }
                
            case .failure(let error):
                self.handleError(error, action: "lắng nghe thay đổi cửa hàng")
            }
        }
        
        if let listener = ingredientsListener {
            addToListeners(listener)
        }
    }

    // MARK: - Loading State Management
    func withLoading<T>(_ text: String? = nil, operation: () async throws -> T) async throws -> T {
        await MainActor.run {
            isLoading = true
            loadingText = text
        }
        defer {
            Task { @MainActor in
                isLoading = false
                loadingText = nil
            }
        }
        return try await operation()
    }
    
    func withProgress<T>(_ operation: (@escaping (Double) -> Void) async throws -> T) async throws -> T {
        await MainActor.run { isLoading = true }
        defer {
            Task { @MainActor in
                isLoading = false
                progress = nil
            }
        }
        return try await operation { [weak self] value in
            Task { @MainActor in self?.progress = value }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
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
    
    func resetState() {
        currentUser = nil
        selectedShop = nil
        error = nil
        alert = nil
        userId = ""
        selectedShopId = ""
        listeners.removeAll()
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
