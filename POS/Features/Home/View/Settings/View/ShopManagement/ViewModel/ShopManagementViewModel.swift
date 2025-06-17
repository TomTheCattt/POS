import SwiftUI
import Combine

@MainActor
final class ShopManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    var activatedShop: Shop?
    var shops: [Shop] = []
    @Published var searchText: String = ""
    @Published var currentView: ViewType = .menu
    @Published var shopName: String = ""
    @Published var address: String = ""
    @Published var groundRent: Double = 0.0
    @Published var currency: Currency = .vnd
    @Published var isActive: Bool = true
    @Published var voucherName: String = ""
    @Published var voucherValue: Double = 0
    @Published var openTime = Date()
    @Published var closeTime = Date()
    @Published var discountVouchers: [DiscountVoucher] = []
    @Published var pointRate: Double = 0
    @Published var isOwnerAuthenticated: Bool = false
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View State
    enum ViewType {
        case menu
        case inventory
    }
    
    // MARK: - Computed Properties
    
    var remainingTimeString: String {
        source.remainingTimeString
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        source.currentShopsPublisher
            .sink { [weak self] shops in
                guard let self = self, let shops = shops else { return }
                self.shops = shops
                self.activatedShop = shops.first(where: { $0.isActive })
            }
            .store(in: &cancellables)
        source.isOwnerAuthenticatedPublisher
            .sink { [weak self] rs in
                guard let self = self, let rs = rs else { return }
                self.isOwnerAuthenticated = rs
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Shop Management Methods
    func canAddNewShop() -> Bool {
        guard let userId = source.currentUser?.id else { return false }
        let userShops = shops.filter { $0.ownerId == userId }
        return userShops.count < Shop.maxShopsPerUser
    }
    
    func createNewShop() async throws {
        guard let userId = source.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])
        }
        
        guard !shopName.isEmpty else {
            return
        }
        
        do {
            // Validate before creating
            try Shop.validate(shopName: shopName, groundRent: 0, ownerId: userId, existingShops: shops)
            
            let businessHours = BusinessHours(open: openTime, close: closeTime)
            
            // Create new shop
            let newShop = Shop(shopName: shopName, isActive: false, createdAt: Date(), updatedAt: Date(), ownerId: userId, groundRent: 0, currency: .vnd, address: address, businessHours: businessHours, pointRate: 0.05)
            
            // Save to database
            let _ = try await source.environment.databaseService.createShop(newShop, userId: userId)
            
        } catch {
//            self.error = error
//            throw error
        }
    }
    
    func selectShop(_ shop: Shop) async {
        activatedShop = shop
        await source.switchShop(to: shop)
    }
    
    func deleteShop(_ shop: Shop) async {
        do {
            try await source.withLoading {
                guard let userId = source.currentUser?.id,
                      let shopId = activatedShop?.id else { return }
                try await source.environment.databaseService.deleteShop(userId: userId, shopId: shopId)
            }
        } catch {
            source.handleError(error)
        }
    }
    
    func toggleView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentView = currentView == .menu ? .inventory : .menu
        }
    }
    
    func addVoucher() {
        let newVoucher = DiscountVoucher(name: voucherName, value: voucherValue)
        discountVouchers.append(newVoucher)
        voucherName = ""
        voucherValue = 0
    }
    
    var searchPlaceholder: String {
        switch currentView {
        case .menu:
            return "Tìm kiếm món..."
        case .inventory:
            return "Tìm kiếm sản phẩm..."
        }
    }
} 
