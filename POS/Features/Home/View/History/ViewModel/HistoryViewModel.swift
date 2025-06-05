import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var selectedDateRange: DateRange = .today
    @Published private(set) var orders: [Order] = []
    @Published private(set) var filteredOrders: [Order] = []
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        source.ordersPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] orders in
                guard let self = self else { return }
                self.orders = orders ?? []
                self.filterOrders()
            }
            .store(in: &cancellables)
        
        // Lắng nghe thay đổi từ searchText
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterOrders()
            }
            .store(in: &cancellables)
        
        // Lắng nghe thay đổi từ selectedDateRange
        $selectedDateRange
            .sink { [weak self] _ in
                self?.filterOrders()
            }
            .store(in: &cancellables)
            
        // Lắng nghe trạng thái loading từ SourceModel
        source.loadingPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] loading, _ in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func filterOrders() {
        let dateInterval = selectedDateRange.dateInterval
        
        filteredOrders = orders.filter { order in
            var matchesSearch = true
            var matchesDate = true
            
            // Lọc theo từ khóa tìm kiếm
            if !searchText.isEmpty {
                matchesSearch = order.id?.localizedCaseInsensitiveContains(searchText) ?? false ||
                              order.items.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
            
            // Lọc theo khoảng thời gian
            if let interval = dateInterval {
                matchesDate = interval.contains(order.createdAt)
            }
            
            return matchesSearch && matchesDate
        }
        
        // Sắp xếp theo thời gian mới nhất
        filteredOrders.sort { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Public Methods
    func deleteOrder(_ order: Order) async throws {
        guard let orderId = order.id else {
            throw AppError.order(.notFound)
        }
        
        guard let userId = source.currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = source.activatedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        do {
            try await source.environment.databaseService.delete(
                id: orderId,
                from: .orders,
                type: .nestedSubcollection(userId: userId, shopId: shopId)
            )
        } catch {
            source.handleError(error, action: "xóa đơn hàng")
            throw error
        }
    }
    
    func formatPrice(_ price: Double) -> String {
        return String(format: "%.2f", price)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types
enum DateRange: String, CaseIterable {
    case today = "Hôm nay"
    case yesterday = "Hôm qua"
    case thisWeek = "Tuần này"
    case thisMonth = "Tháng này"
    case custom = "Tùy chọn"
    
    var dateInterval: DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.dateInterval(of: .day, for: now)
        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
            return calendar.dateInterval(of: .day, for: yesterday)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)
        case .custom:
            return nil
        }
    }
} 
