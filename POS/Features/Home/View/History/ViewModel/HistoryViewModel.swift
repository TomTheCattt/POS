import SwiftUI
import Combine

final class HistoryViewModel: BaseViewModel {
    var errorMessage: String?
    
    var showError: Bool = false
    
    // MARK: - Dependencies
    let environment: AppEnvironment
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var selectedDateRange: DateRange = .today
    
    // MARK: - Computed Properties
    var filteredOrders: [Order] {
        orders.filter { order in
            if !searchText.isEmpty {
                return ((order.id?.localizedCaseInsensitiveContains(searchText)) != nil)
            }
            return true
        }
    }
    
    // MARK: - Initialization
    required init(environment: AppEnvironment) {
        self.environment = environment
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
        isLoading = true
        
        Task {
            do {
                let fetchedOrders = try await orderService.fetchOrders()
                await MainActor.run {
                    self.orders = fetchedOrders
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // TODO: Handle error
                    print("Error loading orders: \(error)")
                }
            }
        }
    }
    
    func deleteOrder(_ order: Order) {
        Task {
            do {
                try await orderService.deleteOrder(order)
                await MainActor.run {
                    if let index = orders.firstIndex(where: { $0.id == order.id }) {
                        orders.remove(at: index)
                    }
                }
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
