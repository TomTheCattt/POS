import SwiftUI
import Combine

final class AnalyticsViewModel: BaseViewModel {
    var errorMessage: String?
    
    var showError: Bool = false
    
    // MARK: - Dependencies
    let environment: AppEnvironment
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published private(set) var totalRevenue: Double = 0
    @Published private(set) var totalOrders: Int = 0
    @Published private(set) var averageOrderValue: Double = 0
    @Published private(set) var topSellingItems: [MenuItem] = []
    @Published private(set) var revenueByDay: [Date: Double] = [:]
    @Published var isLoading: Bool = false
    
    // MARK: - Initialization
    init(environment: AppEnvironment) {
        self.environment = environment
        loadAnalytics()
    }
    
    // MARK: - Private Methods
    private func loadAnalytics() {
        isLoading = true
        
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
