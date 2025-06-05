import SwiftUI
import Combine

@MainActor
final class ShopManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    var activatedShop: Shop?
    var shops: [Shop] = []
    @Published var searchText: String = ""
    @Published var currentView: ViewType = .menu
    
    // MARK: - Dependencies
    private let source: SourceModel
    
    // MARK: - View State
    enum ViewType {
        case menu
        case inventory
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
        // Lắng nghe thay đổi danh sách shops
//        Task {
//            do {
//                guard let userId = source.currentUser?.id else { return }
//                shops = try await source.environment.databaseService.getAllShops(userId: userId)
//                
//                if let firstShop = shops.first {
//                    await selectShop(firstShop)
//                }
//            } catch {
//                source.handleError(error, action: "tải danh sách cửa hàng")
//            }
//        }
    }
    
    // MARK: - Public Methods
    func selectShop(_ shop: Shop) async {
        activatedShop = shop
        if shop.isActive {
            await source.deactivateShop(shop)
        } else {
            await source.activateShop(shop)
        }
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
