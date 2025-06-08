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
    
    // MARK: - Dependencies
    private let source: SourceModel
    
    // MARK: - View State
    enum ViewType {
        case menu
        case inventory
    }
    
    // MARK: - Computed Properties
    var isOwnerAuthenticated: Bool = false
    
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
            .store(in: &source.cancellables)
        source.isOwnerAuthenticatedPublisher
            .sink { [weak self] rs in
                guard let self = self, let rs = rs else { return }
                self.isOwnerAuthenticated = rs
            }
            .store(in: &source.cancellables)
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
            
            // Create new shop
            let newShop = Shop(shopName: shopName, isActive: false, createdAt: Date(), updatedAt: Date(), ownerId: userId, groundRent: 0, currency: .vnd, address: address)
            
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
    
    func toggleView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentView = currentView == .menu ? .inventory : .menu
        }
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
