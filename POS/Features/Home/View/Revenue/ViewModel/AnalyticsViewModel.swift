import SwiftUI
import FirebaseCore
import Combine

@MainActor
final class RevenueRecordViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var revenueRecords: [RevenueRecord] = []
    @Published private(set) var isLoading: Bool = false
    
    private var menuItems: [MenuItem] = []
    
    // Computed Properties cho revenueRecord View
    var totalRevenue: Double {
        revenueRecords.reduce(0) { $0 + $1.revenue }
    }
    
    var totalOrders: Int {
        revenueRecords.reduce(0) { $0 + $1.totalOrders }
    }
    
    var averageOrderValue: Double {
        guard totalOrders > 0 else { return 0 }
        return totalRevenue / Double(totalOrders)
    }
    
    var topSellingItem: (name: String, quantity: Int)? {
        // Gộp tất cả topSellingItems từ các record
        let allItems = revenueRecords.reduce(into: [String: Int]()) { result, record in
            record.topSellingItems.forEach { itemId, quantity in
                result[itemId, default: 0] += quantity
            }
        }
        
        // Tìm item bán chạy nhất
        guard let maxItem = allItems.max(by: { $0.value < $1.value }),
              let menuItem = menuItems.first(where: { $0.id == maxItem.key }) else {
            return nil
        }
        
        return (name: menuItem.name, quantity: maxItem.value)
    }
    
    var peakHours: [(hour: Int, revenue: Double, percentage: Double)] {
        // Gộp tất cả peakHours từ các record
        let allHours = revenueRecords.reduce(into: [Int: Double]()) { result, record in
            record.peakHours.forEach { hour, revenue in
                result[hour, default: 0] += revenue
            }
        }
        
        let totalRevenue = allHours.values.reduce(0, +)
        
        // Chuyển đổi và sắp xếp theo doanh thu
        return allHours.map { hour, revenue in
            (
                hour: hour,
                revenue: revenue,
                percentage: totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0
            )
        }
        .sorted { $0.revenue > $1.revenue }
    }
    
    var bestDayOfWeek: (day: Int, revenue: Double, percentage: Double)? {
        // Gộp tất cả dayOfWeekRevenue từ các record
        let allDays = revenueRecords.reduce(into: [Int: Double]()) { result, record in
            record.dayOfWeekRevenue.forEach { day, revenue in
                result[day, default: 0] += revenue
            }
        }
        
        let totalRevenue = allDays.values.reduce(0, +)
        
        // Tìm ngày có doanh thu cao nhất
        guard let maxDay = allDays.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        return (
            day: maxDay.key,
            revenue: maxDay.value,
            percentage: totalRevenue > 0 ? (maxDay.value / totalRevenue) * 100 : 0
        )
    }
    
    var newCustomers: Int {
        revenueRecords.reduce(0) { $0 + $1.newCustomers }
    }
    
    var returningCustomers: Int {
        revenueRecords.reduce(0) { $0 + $1.returningCustomers }
    }
    
    var totalCustomers: Int {
        revenueRecords.reduce(0) { $0 + $1.totalCustomers }
    }
    
    var returnRate: Double {
        guard totalCustomers > 0 else { return 0 }
        return Double(returningCustomers) / Double(totalCustomers) * 100
    }
    
    var paymentMethodStats: [(method: PaymentMethod, count: Int, percentage: Double)] {
        // Gộp tất cả paymentMethods từ các record
        let allMethods = revenueRecords.reduce(into: [String: Int]()) { result, record in
            record.paymentMethods.forEach { method, count in
                result[method, default: 0] += count
            }
        }
        
        let totalCount = Double(allMethods.values.reduce(0, +))
        
        // Chuyển đổi và sắp xếp theo số lượng
        return allMethods.compactMap { methodString, count in
            guard let method = PaymentMethod(rawValue: methodString) else { return nil }
            return (
                method: method,
                count: count,
                percentage: totalCount > 0 ? (Double(count) / totalCount) * 100 : 0
            )
        }
        .sorted { $0.count > $1.count }
    }
    
    private let source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        source.revenueRecordsPublisher
            .sink { [weak self] revenueRecords in
                guard let self = self,
                      let revenueRecords = revenueRecords else { return }
                self.revenueRecords = revenueRecords
            }
            .store(in: &cancellables)
            
        source.menuItemsPublisher
            .sink { [weak self] menuItems in
                guard let self = self,
                      let menuItems = menuItems else { return }
                self.menuItems = menuItems
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadData(for timeFilter: TimeFilter) {
        Task {
            do {
                isLoading = true
                let calendar = Calendar.current
                let now = Date()
                let startDate: Date
                
                switch timeFilter {
                case .day:
                    startDate = calendar.date(byAdding: .day, value: -1, to: now)!
                case .week:
                    startDate = calendar.date(byAdding: .day, value: -7, to: now)!
                case .month:
                    startDate = calendar.date(byAdding: .month, value: -1, to: now)!
                }
                
                let records: [RevenueRecord] = try await source.environment.databaseService.getRevenueRecords(
                    userId: source.userId,
                    shopId: source.activatedShop?.id ?? "") { query in
                        query
                            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                            .whereField("date", isLessThanOrEqualTo: Timestamp(date: now))
                            .order(by: "date")
                    }
                
                self.revenueRecords = records
                isLoading = false
            } catch {
                isLoading = false
                source.handleError(error)
            }
        }
    }
} 
