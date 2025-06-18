import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var selectedDateRange: DateRange = .today
    @Published private(set) var orders: [Order] = []
    @Published private(set) var filteredOrders: [Order] = []
    
    // MARK: - Dependencies
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        // Kết hợp các Publisher để theo dõi thay đổi
        Publishers.CombineLatest3(
            source.ordersPublisher,
            $searchText.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
            $selectedDateRange
        )
        .sink { [weak self] (orders, searchText, dateRange) in
            guard let self = self else { return }
            self.orders = orders ?? []
            self.filterOrders(searchText: searchText, dateRange: dateRange)
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func filterOrders(searchText: String, dateRange: DateRange) {
        let dateInterval = dateRange.dateInterval
        
        let filtered = orders.filter { order in
            // Kiểm tra điều kiện về thời gian
            guard let interval = dateInterval else { return true }
            let matchesDate = interval.contains(order.createdAt)
            guard matchesDate else { return false }
            
            // Nếu không có searchText, trả về true
            guard !searchText.isEmpty else { return true }
            
            // Tìm kiếm theo ID
            if let id = order.id,
               id.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Tìm kiếm theo tên các món
            if order.items.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) {
                return true
            }
            
            // Tìm kiếm theo phương thức thanh toán
            if order.paymentMethod.rawValue.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Tìm kiếm theo số tiền
            if formatPrice(order.totalAmount).localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            return false
        }
        
        // Sắp xếp theo thời gian mới nhất
        filteredOrders = filtered.sorted { $0.createdAt > $1.createdAt }
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "."
        
        let number = NSNumber(value: price)
        return (formatter.string(from: number) ?? "0") + "đ"
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
enum DateRange: String, CaseIterable, Identifiable {
    case today = "Hôm nay"
    case yesterday = "Hôm qua"
    case thisWeek = "Tuần này"
    case thisMonth = "Tháng này"
    case custom = "Tùy chọn"
    
    var id: String { self.rawValue }
    
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
