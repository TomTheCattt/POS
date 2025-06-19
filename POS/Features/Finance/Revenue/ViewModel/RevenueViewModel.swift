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
        let allItems = revenueRecords.flatMap { record in
            record.topSellingItems.map { (name: $0.key, quantity: $0.value) }
        }
        
        let groupedItems = Dictionary(grouping: allItems, by: { $0.name })
            .mapValues { items in items.reduce(0) { $0 + $1.quantity } }
        
        return groupedItems.max(by: { $0.value < $1.value })
            .map { (name: $0.key, quantity: $0.value) }
    }
    
    var peakHours: [(hour: Int, percentage: Double)] {
        let allHours = revenueRecords.flatMap { record in
            record.peakHours.map { (hour: $0.key, revenue: $0.value) }
        }
        
        let groupedHours = Dictionary(grouping: allHours, by: { $0.hour })
            .mapValues { hours in hours.reduce(0) { $0 + $1.revenue } }
        
        let totalRevenue = groupedHours.values.reduce(0, +)
        
        return groupedHours.map { (hour: $0.key, percentage: totalRevenue > 0 ? ($0.value / totalRevenue) * 100 : 0) }
            .sorted { $0.percentage > $1.percentage }
    }
    
    var bestDayOfWeek: (day: Int, percentage: Double)? {
        let allDays = revenueRecords.flatMap { record in
            record.dayOfWeekRevenue.map { (day: $0.key, revenue: $0.value) }
        }
        
        let groupedDays = Dictionary(grouping: allDays, by: { $0.day })
            .mapValues { days in days.reduce(0) { $0 + $1.revenue } }
        
        let totalRevenue = groupedDays.values.reduce(0, +)
        
        return groupedDays.max(by: { $0.value < $1.value })
            .map { (day: $0.key, percentage: totalRevenue > 0 ? ($0.value / totalRevenue) * 100 : 0) }
    }
    
    var newCustomers: Int {
        revenueRecords.reduce(0) { $0 + $1.newCustomers }
    }
    
    var returningCustomers: Int {
        revenueRecords.reduce(0) { $0 + $1.returningCustomers }
    }
    
    var returnRate: Double {
        let totalNew = revenueRecords.reduce(0) { $0 + $1.newCustomers }
        let totalReturning = revenueRecords.reduce(0) { $0 + $1.returningCustomers }
        let totalCustomers = totalNew + totalReturning
        
        guard totalCustomers > 0 else { return 0 }
        return (Double(totalReturning) / Double(totalCustomers)) * 100
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
