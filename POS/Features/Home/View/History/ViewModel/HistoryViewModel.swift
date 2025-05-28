import SwiftUI
import Combine

final class HistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var selectedDateRange: DateRange = .today
    
    private var source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredOrders: [Order] {
//        source.ordersPublisher
//            .sink { orders in
//                orders?.filter { order in
//                    if !searchText.isEmpty {
//                        return ((order.id?.localizedCaseInsensitiveContains(searchText)) != nil)
//                    }
//                    return true
//                }
//            }
//            .store(in: &cancellables)
        []
    }
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
        loadOrders()
    }
    
    private func setupBindings() {
        // Observe date range changes
        $selectedDateRange
            .dropFirst()
            .sink { [weak self] _ in
                self?.loadOrders()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadOrders() {
        
        Task {
            do {
                let orders: [Order] = try await source.environment.databaseService.getAll(from: .orders, type: .collection)
                
//                await MainActor.run {
//                    self.orders = orders
//                    self.isLoading = false
//                }
            } catch {
                await MainActor.run {
//                    self.isLoading = false
                    // TODO: Handle error
                    print("Error loading orders: \(error)")
                }
            }
        }
    }
    
    func deleteOrder(_ order: Order) async throws {
        Task {
            do {
                guard let orderId = order.id else {
                    throw AppError.order(.notFound)
                }
                try await source.environment.databaseService.delete(id: orderId, from: .orders, type: .collection)
//                await MainActor.run {
//                    if let index = orders.firstIndex(where: { $0.id == order.id }) {
//                        orders.remove(at: index)
//                    }
//                }
            } catch {
                // TODO: Handle error
                print("Error deleting order: \(error)")
            }
        }
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
