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
    
    // Settings & Theme
    @Published private(set) var currentLanguage: AppLanguage = .vietnamese
    @Published private(set) var currentThemeStyle: AppThemeStyle = .default
    @Published private(set) var currentThemeColors: AppThemeColors = AppThemeStyle.default.colors
    
    // UI State
    @Published private(set) var appThemeColors: AppThemeColors?
    @Published private(set) var appLanguage: AppLanguage?
    
    // Session State
    @AppStorage("lastActiveRoute") private var lastActiveRoute: String = ""
    @AppStorage("lastActiveShopId") private var lastActiveShopId: String = ""
    @AppStorage("lastActiveMenuId") private var lastActiveMenuId: String = ""
    @AppStorage("lastActiveOrderId") private var lastActiveOrderId: String = ""
    @AppStorage("lastActiveTimestamp") private var lastActiveTimestamp: Double = 0
    @AppStorage("sessionData") private var sessionData: Data = Data()
    
    // Authentication
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var isOwnerAuthenticated: Bool?
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var authAttempts = 0
    @Published private(set) var isLocked = false
    @Published private(set) var lockEndTime: Date?
    
    // Shop Management
    @Published private(set) var shops: [Shop]?
    @Published private(set) var activatedShop: Shop?
    
    // Menu Management
    @Published private(set) var menuList: [AppMenu]?
    @Published private(set) var activatedMenu: AppMenu?
    @Published private(set) var menuItems: [MenuItem]?
    
    // Order Management
    @Published private(set) var orders: [Order]?
    
    // Ingredient Management
    @Published private(set) var ingredients: [IngredientUsage]?
    
    // Staff Management
    @Published private(set) var staffs: [Staff]?
    
    // Customer Management
    @Published private(set) var customers: [Customer]?
    
    // Revenue Record Management
    @Published private(set) var revenueRecords: [RevenueRecord]?
    
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
    
    // Thêm các thuộc tính mới cho background session
    @AppStorage("sessionStartTime") private var sessionStartTime: Double = 0
    @AppStorage("lastRemainingTime") private var lastRemainingTime: Double = 0
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Computed Properties
    var remainingTimeString: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var lockEndTimeRemaining: String? {
        if let lockEndTime = lockEndTime {
            let remaining = Int(lockEndTime.timeIntervalSinceNow)
            if remaining <= 0 {
                isLocked = false
                authAttempts = 0
                self.lockEndTime = nil
                return nil
            }
            
            let minutes = (remaining / 60) % 60
            let seconds = remaining % 60
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return nil
        }
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
    
    // Ingredient Management
    var ingredientsPublisher: AnyPublisher<[IngredientUsage]?, Never> {
        $ingredients.eraseToAnyPublisher()
    }
    
    // Staff Management
    var staffsPublisher: AnyPublisher<[Staff]?, Never> {
        $staffs.eraseToAnyPublisher()
    }
    
    // Customer Management
    var customersPublisher: AnyPublisher<[Customer]?, Never> {
        $customers.eraseToAnyPublisher()
    }
    
    var revenueRecordsPublisher: AnyPublisher<[RevenueRecord]?, Never> {
        $revenueRecords.eraseToAnyPublisher() 
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
    
    var languagePublisher: AnyPublisher<AppLanguage, Never> {
        $currentLanguage.eraseToAnyPublisher()
    }
    
    var themeStylePublisher: AnyPublisher<AppThemeStyle, Never> {
        $currentThemeStyle.eraseToAnyPublisher()
    }
    
    var themeColorsPublisher: AnyPublisher<AppThemeColors, Never> {
        $currentThemeColors.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization & Cleanup
    init(environment: AppEnvironment = AppEnvironment()) {
        self.environment = environment
        
        setupAuthStateListener()
        setupSettingsSubscriptions()
        
        // Khôi phục phiên nếu có
        if sessionStartTime > 0 {
            resumeSession()
        }
        
        // Khôi phục trạng thái phiên làm việc
        if let sessionInfo = restoreSessionState() {
            Task { @MainActor in
                await restoreWorkSession(sessionInfo)
            }
        }
    }
    
    deinit {
        Task { @MainActor [weak self] in
            await self?.cleanupResources()
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
                    await self?.handleSignOut()
                case .emailNotVerified:
                    await self?.handleEmailNotVerified()
                }
            }
        }
    }
    
    private func handleAuthStateChange(_ user: FirebaseAuth.User?) async {
        do {
            try await withLoading("Đang xác thực người dùng...") {
                if let user = user {
                    // 1. Kiểm tra email verification
                    try await environment.authService.checkEmailVerification()
                    
                    // 2. Lấy dữ liệu user từ database
                    if let userData: AppUser = try await environment.databaseService.getUser(userId: user.uid) {
                        // 3. Lưu userId vào UserDefaults nếu chưa có
                        if userId.isEmpty {
                            await MainActor.run {
                                self.userId = userData.id!
                            }
                        }
                        
                        // 4. Fetch shops và dữ liệu liên quan
                        await fetchShops(for: userData.id!)
                        
                        // 5. Cập nhật currentUser cuối cùng để trigger UI update
                        await MainActor.run {
                            self.currentUser = userData
                        }
                    } else {
                        // Không tìm thấy user trong database
                        await handleSignOut()
                    }
                } else {
                    await handleSignOut()
                }
            }
        } catch let error as AppError {
            if case .auth(.unverifiedEmail) = error {
                await MainActor.run {
                    self.userId = user?.uid ?? ""
                    self.currentUser = nil
                }
            } else {
                await handleSignOut()
            }
        } catch {
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
//            guard userId.isEmpty else { return }
            
            if let userData: AppUser = try await environment.databaseService.getUser(userId: userId) {
                await fetchShops(for: userId)
                
                await MainActor.run {
                    self.currentUser = userData
                }
            }
        } catch {
            self.currentUser = nil
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
        
        guard !userId.isEmpty else {
            handleError(AppError.auth(.userNotFound))
            return
        }
        
        await fetchShopMenu(shopId: shopId)
        await fetchShopOrders(shopId: shopId)
        await fetchShopIngredients(shopId: shopId)
        await fetchShopStaffs(shopId: shopId)
        await fetchShopCustomers(shopId: shopId)
        await fetchShopRevenueRecords(shopId: shopId)
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
            environment.hapticsService.impact(.medium)
            
        } catch {
            handleError(AppError.shop(.updateFailed))
        }
    }
    
    func activateShop(_ shop: Shop) async {
        guard let shopId = activatedShop?.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        do {
            if let currentActiveShop = self.shops?.first(where: { $0.isActive && $0.id != shopId }) {
                var updatedCurrentShop = currentActiveShop
                updatedCurrentShop.isActive = false
                let _ = try await environment.databaseService.updateShop(
                    updatedCurrentShop,
                    userId: userId,
                    shopId: shopId
                )
            }
            
            var updatedShop = shop
            updatedShop.isActive = true
            let _ = try await environment.databaseService.updateShop(
                updatedShop,
                userId: userId,
                shopId: shopId
            )
            self.activatedShop = updatedShop
            showSuccess("Đã kích hoạt cửa hàng \(shop.shopName)")
        } catch {
            handleError(error, action: "kích hoạt cửa hàng")
        }
    }
    
    func deactivateShop(_ shop: Shop) async {
        guard let shopId = activatedShop?.id else {
            handleError(AppError.shop(.notFound))
            return
        }
        
        do {
            if let anotherShop = self.shops?.first(where: { $0.id != shopId }) {
                var updatedCurrentShop = shop
                updatedCurrentShop.isActive = false
                let _ = try await environment.databaseService.updateShop(
                    updatedCurrentShop,
                    userId: userId,
                    shopId: shopId
                )
                
                await activateShop(anotherShop)
            } else {
                showError("Không thể tắt cửa hàng duy nhất")
            }
        } catch {
            handleError(error, action: "tắt cửa hàng")
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
    
    // MARK: - Staff Management Methods
    private func fetchShopStaffs(shopId: String) async {
        do {
            staffs = try await environment.databaseService.getAllStaffs(userId: userId, shopId: shopId)
        } catch {
            handleError(error, action: "tải danh sách nhân viên")
        }
    }
    
    // MARK: - Customer Management Methods
    private func fetchShopCustomers(shopId: String) async {
        do {
            staffs = try await environment.databaseService.getAllCustomers(userId: userId, shopId: shopId)
        } catch {
            handleError(error, action: "tải danh sách khách hàng")
        }
    }
    
    // MARK: - Revenue Record Management Methods
    private func fetchShopRevenueRecords(shopId: String) async {
        do {
            staffs = try await environment.databaseService.getAllRevenueRecords(userId: userId, shopId: shopId)
        } catch {
            handleError(error, action: "tải báo cáo doanh thu")
        }
    }
    
    // MARK: - Listener Management
    
    func setupCurrentUserListener() {
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.listenToCurrentUser(userId: userId) { [weak self] (result: Result<AppUser?, Error>) in
            guard let self = self else { return }
            Task {
                switch result {
                case .success(let user):
                    self.currentUser = user
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi thông tin người dùng")
                }
            }
        }
    }
    
    func removeCurrentUserListener() {
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.removeCurrentUserListener(userId: userId)
    }
    
    func setupShopsListener() {
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.listenToShops(userId: userId, queryBuilder: nil, completion: { [weak self] (result: Result<[Shop], Error>) in
            guard let self = self else { return }
            
            Task {
                switch result {
                case .success(let shops):
                    self.shops = shops
                    self.activatedShop = shops.first(where: { $0.isActive })
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi cửa hàng")
                }
            }
        })
    }
    
    func removeShopsListener() {
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.removeShopsListener(userId: userId)
    }
    
    func setupMenuListListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            menuList = []
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            menuList = []
            return
        }
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
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            return
        }
        environment.databaseService.removeMenuCollectionListener(userId: userId, shopId: shopId)
    }
    
    func setupOrdersListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            orders = []
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            orders = []
            return
        }
        
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
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.removeOrdersListener(userId: userId, shopId: shopId)
    }
    
    func setupIngredientsListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            ingredients = []
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            ingredients = []
            return
        }
        
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
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.removeIngredientsListener(userId: userId, shopId: shopId)
    }
    
    func setupStaffsListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            staffs = []
            return
        }
        
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            staffs = []
            return
        }
        
        environment.databaseService.listenToStaffs(
            userId: userId,
            shopId: shopId,
            queryBuilder: { $0.order(by: "name", descending: false) }
        ) { [weak self] (result: Result<[Staff], Error>) in
            guard let self = self else { return }
            
            Task {
                switch result {
                case .success(let staffs):
                    self.staffs = staffs
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi nhân viên")
                }
            }
        }
    }
    
    func removeStaffsListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.removeStaffsListener(userId: userId, shopId: shopId)
    }
    
    func setupCustomersListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            customers = []
            return
        }
        
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            customers = []
            return
        }
        
        environment.databaseService.listenToCustomers(
            userId: userId,
            shopId: shopId,
            queryBuilder: nil
        ) { [weak self] (result: Result<[Customer], Error>) in
            guard let self = self else { return }
            
            Task {
                switch result {
                case .success(let customers):
                    self.customers = customers
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi khách hàng")
                }
            }
        }
    }
    
    func removeCustomersListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.removeCustomersListener(userId: userId, shopId: shopId)
    }
    
    func setupRevenueRecordsListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            revenueRecords = []
            return
        }
        
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            revenueRecords = []
            return
        }
        
        environment.databaseService.listenToRevenueRecords(
            userId: userId,
            shopId: shopId,
            queryBuilder: { $0.order(by: "date", descending: false) }
        ) { [weak self] (result: Result<[RevenueRecord], Error>) in
            guard let self = self else { return }
            
            Task {
                switch result {
                case .success(let revenueRecords):
                    self.revenueRecords = revenueRecords
                case .failure(let error):
                    self.handleError(error, action: "lắng nghe thay đổi báo cáo doanh thu")
                }
            }
        }
    }
    
    func removeRevenueRecordsListener(shopId: String) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            return
        }
        environment.databaseService.removeRevenueRecordsListener(userId: userId, shopId: shopId)
    }
    
    func setupMenuItemsListener(shopId: String, menuId: String?) {
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            menuItems = []
            return
        }
        guard let userId = currentUser?.id else {
            showError(AppError.auth(.userNotFound).localizedDescription)
            menuItems = []
            return
        }
        
        guard let activatedMenu, let activatedMenuId = activatedMenu.id else {
            self.menuItems = []
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
        guard !shopId.isEmpty else {
            showError(AppError.shop(.notFound).localizedDescription)
            return
        }
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
        endBackgroundTask()
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
    
    func showAlert(title: String, message: String, primaryButton: AlertButton? = nil, secondaryButton: AlertButton? = nil) {
        alert = AlertItem(title: title, message: message, primaryButton: primaryButton, secondaryButton: secondaryButton)
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
        clearSessionState()
        await removeAllListeners()
    }
    
    // MARK: - Owner Authentication Methods
    func authenticateAsOwner(password: String) -> Bool {
        guard password == currentUser?.ownerPassword else {
            authAttempts += 1
            environment.hapticsService.notification(.error)
            if authAttempts >= 3 {
                isLocked = true
                lockEndTime = Date().addingTimeInterval(3600)
                environment.hapticsService.impact(.heavy)
            }
            return false
        }
        
        isOwnerAuthenticated = true
        isLocked = false
        lockEndTime = nil
        startAuthTimer()
        startRemainingTimer()
        remainingTime = authTimeoutInterval
        
        // Lưu thời gian bắt đầu phiên
        sessionStartTime = Date().timeIntervalSince1970
        lastRemainingTime = authTimeoutInterval
        
        // Đăng ký background task
        registerBackgroundTask()
        
        return true
    }
    
    func logoutAsOwner() {
        isOwnerAuthenticated = false
        invalidateAuthTimer()
        invalidateRemainingTimer()
        remainingTime = 0
        
        // Xóa thông tin phiên
        sessionStartTime = 0
        lastRemainingTime = 0
        
        // Kết thúc background task
        endBackgroundTask()
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
                    self.lastRemainingTime = self.remainingTime
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
    
    // MARK: - Background Session Management
    private func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func resumeSession() {
        guard let isOwnerAuthenticated = isOwnerAuthenticated, isOwnerAuthenticated else { return }
        
        let currentTime = Date().timeIntervalSince1970
        let elapsedTime = currentTime - sessionStartTime
        
        if elapsedTime >= authTimeoutInterval {
            // Phiên đã hết hạn
            logoutAsOwner()
        } else {
            // Cập nhật thời gian còn lại
            remainingTime = max(0, authTimeoutInterval - elapsedTime)
            lastRemainingTime = remainingTime
            
            // Khởi động lại timers
            startAuthTimer()
            startRemainingTimer()
            
            // Đăng ký lại background task
            registerBackgroundTask()
        }
    }
    
    private func setupSettingsSubscriptions() {
        // Subscribe to language changes
        environment.settingsService.languagePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] language in
                self?.currentLanguage = language
            }
            .store(in: &cancellables)
        
        // Subscribe to theme style changes
        environment.settingsService.themeStylePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] style in
                self?.currentThemeStyle = style
                self?.currentThemeColors = style.colors
            }
            .store(in: &cancellables)
        
        // Subscribe to theme colors changes
        environment.settingsService.themeColorsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] colors in
                self?.currentThemeColors = colors
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Session Management
    func saveSessionState(route: Route, shopId: String? = nil, menuId: String? = nil, orderId: String? = nil) {
        lastActiveRoute = route.id
        lastActiveShopId = shopId ?? ""
        lastActiveMenuId = menuId ?? ""
        lastActiveOrderId = orderId ?? ""
        lastActiveTimestamp = Date().timeIntervalSince1970
        
        // Lưu dữ liệu phiên hiện tại
        let sessionInfo = SessionInfo(
            route: route,
            shopId: shopId,
            menuId: menuId,
            orderId: orderId,
            timestamp: lastActiveTimestamp,
            currentShop: activatedShop,
            currentMenu: activatedMenu,
            currentOrder: orders?.first(where: { $0.id == orderId })
        )
        
        if let encodedData = try? JSONEncoder().encode(sessionInfo) {
            sessionData = encodedData
        }
    }
    
    func restoreSessionState() -> SessionInfo? {
        guard !sessionData.isEmpty else { return nil }
        
        // Kiểm tra thời gian phiên có hợp lệ không (ví dụ: 24 giờ)
        let sessionTimeout: TimeInterval = 24 * 60 * 60
        if Date().timeIntervalSince1970 - lastActiveTimestamp > sessionTimeout {
            clearSessionState()
            return nil
        }
        
        return try? JSONDecoder().decode(SessionInfo.self, from: sessionData)
    }
    
    func clearSessionState() {
        lastActiveRoute = ""
        lastActiveShopId = ""
        lastActiveMenuId = ""
        lastActiveOrderId = ""
        lastActiveTimestamp = 0
        sessionData = Data()
    }
    
    func restoreWorkSession(_ sessionInfo: SessionInfo) async {
        // Khôi phục cửa hàng đang active
        if let shopId = sessionInfo.shopId,
           let shop = shops?.first(where: { $0.id == shopId }) {
            await switchShop(to: shop)
        }
        
        // Khôi phục menu đang active
        if let menuId = sessionInfo.menuId,
           let menu = menuList?.first(where: { $0.id == menuId }) {
            await activateMenu(menu)
        }
        
        // Khôi phục đơn hàng đang xem
//        if let orderId = sessionInfo.orderId {
//            // Xử lý khôi phục đơn hàng nếu cần
//        }
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

struct SessionInfo: Codable {
    let route: Route
    let shopId: String?
    let menuId: String?
    let orderId: String?
    let timestamp: TimeInterval
    let currentShop: Shop?
    let currentMenu: AppMenu?
    let currentOrder: Order?
}
