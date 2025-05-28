import SwiftUI
import Combine

final class AnalyticsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var totalRevenue: Double = 0
    @Published private(set) var totalOrders: Int = 0
    @Published private(set) var averageOrderValue: Double = 0
    @Published private(set) var topSellingItems: [MenuItem] = []
    @Published private(set) var revenueByDay: [Date: Double] = [:]
    
    private var source: SourceModel
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        loadAnalytics()
    }
    
    // MARK: - Private Methods
    private func loadAnalytics() {
        
        // Load analytics data from database service
//        databaseService.getAnalytics()
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    self?.isLoading = false
//                    if case .failure(let error) = completion {
//                        print("Error loading analytics: \(error)")
//                    }
//                },
//                receiveValue: { [weak self] analytics in
//                    self?.totalRevenue = analytics.totalRevenue
//                    self?.totalOrders = analytics.totalOrders
//                    self?.averageOrderValue = analytics.averageOrderValue
//                    self?.topSellingItems = analytics.topSellingItems
//                    self?.revenueByDay = analytics.revenueByDay
//                }
//            )
//            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func refresh() {
        loadAnalytics()
    }
} 
