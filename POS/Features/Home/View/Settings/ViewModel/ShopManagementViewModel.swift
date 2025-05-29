import SwiftUI
import Combine

@MainActor
final class ShopManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedShop: Shop?
    @Published var shops: [Shop] = []
    @Published var searchText: String = ""
    @Published var currentView: ViewType = .menu
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
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
        // Lắng nghe thay đổi danh sách shops
        Task {
            do {
                guard let userId = source.currentUser?.id else { return }
                shops = try await source.environment.databaseService.getAllShops(userId: userId)
                
                if let firstShop = shops.first {
                    await selectShop(firstShop)
                }
            } catch {
                source.handleError(error, action: "tải danh sách cửa hàng")
            }
        }
    }
    
    // MARK: - Public Methods
    func selectShop(_ shop: Shop) async {
        selectedShop = shop
        await source.selectShop(shop)
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