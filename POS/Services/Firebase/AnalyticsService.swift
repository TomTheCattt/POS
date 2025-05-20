import Foundation
import FirebaseAnalytics
import FirebaseFirestore
import Combine

final class AnalyticsService: AnalyticsServiceProtocol {
    
    var isLoading: Bool = false
    
    var error: (any Error)?
    
    // MARK: - Singleton
    static let shared = AnalyticsService()
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let analytics = Analytics.self
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Publishers
    private let currentDayStatsSubject = CurrentValueSubject<DailySales, Never>(
        DailySales(
            date: Date(),
            totalSales: 0,
            totalOrders: 0,
            averageOrderValue: 0,
            peakHours: [:],
            paymentMethods: [:]
        )
    )
    
    private let topSellingItemsSubject = CurrentValueSubject<[TopSellingItem], Never>([])
    
    var currentDayStats: AnyPublisher<DailySales, Never> {
        currentDayStatsSubject.eraseToAnyPublisher()
    }
    
    var topSellingItemsPublisher: AnyPublisher<[TopSellingItem], Never> {
        topSellingItemsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private init() {
        setupRealtimeListeners()
    }
    
    // MARK: - Private Methods
    private func setupRealtimeListeners() {
        // Setup real-time listeners for current day stats and top selling items
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        db.collection("sales")
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching daily stats: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Process and update daily stats
                self?.processDailyStats(from: documents)
            }
    }
    
    private func processDailyStats(from documents: [QueryDocumentSnapshot]) {
        var totalSales = 0.0
        let totalOrders = documents.count
        var peakHours: [Int: Int] = [:]
        var paymentMethods: [String: Int] = [:]
        
        for doc in documents {
            if let sale = try? doc.data(as: Sale.self) {
                totalSales += sale.total
                
                // Update peak hours
                let hour = Calendar.current.component(.hour, from: sale.date)
                peakHours[hour, default: 0] += 1
                
                // Update payment methods
                paymentMethods[sale.paymentMethod, default: 0] += 1
            }
        }
        
        let averageOrderValue = totalOrders > 0 ? totalSales / Double(totalOrders) : 0
        
        let dailySales = DailySales(
            date: Date(),
            totalSales: totalSales,
            totalOrders: totalOrders,
            averageOrderValue: averageOrderValue,
            peakHours: peakHours,
            paymentMethods: paymentMethods
        )
        
        currentDayStatsSubject.send(dailySales)
    }
    
    // MARK: - Sales Analytics
    func getDailySales(date: Date) async throws -> DailySales {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let snapshot = try await db.collection("sales")
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .getDocuments()
        
        return try processDailySales(from: snapshot.documents, for: date)
    }
    
    func getSalesReport(from: Date, to: Date) async throws -> SalesReport {
        let snapshot = try await db.collection("sales")
            .whereField("date", isGreaterThanOrEqualTo: from)
            .whereField("date", isLessThan: to)
            .getDocuments()
        
        return try await processSalesReport(from: snapshot.documents, startDate: from, endDate: to)
    }
    
    func getTopSellingItems(limit: Int) async throws -> [TopSellingItem] {
        let snapshot = try await db.collection("menu_items")
            .order(by: "totalSold", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> TopSellingItem? in
            let data = doc.data()
            return TopSellingItem(
                itemId: doc.documentID,
                name: data["name"] as? String ?? "",
                quantity: data["totalSold"] as? Int ?? 0,
                revenue: data["revenue"] as? Double ?? 0,
                profit: data["profit"] as? Double ?? 0
            )
        }
    }
    
    func getSalesTrend(period: AnalyticsPeriod) async throws -> [SalesTrendPoint] {
        let (startDate, interval) = getDateRange(for: period)
        
        let snapshot = try await db.collection("sales")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .order(by: "date")
            .getDocuments()
        
        return try processSalesTrend(from: snapshot.documents, interval: interval)
    }
    
    // MARK: - Customer Analytics
    func getCustomerStats() async throws -> CustomerStats {
        let snapshot = try await db.collection("customers").getDocuments()
        return try processCustomerStats(from: snapshot.documents)
    }
    
    func getCustomerRetentionRate() async throws -> Double {
        // Implement customer retention rate calculation
        return 0.0
    }
    
    func getCustomerLifetimeValue() async throws -> Double {
        // Implement customer lifetime value calculation
        return 0.0
    }
    
    // MARK: - Product Analytics
    func getProductPerformance(productId: String) async throws -> ProductPerformance {
        let doc = try await db.collection("menu_items").document(productId).getDocument()
        guard let data = doc.data() else {
            throw AppError.database(.documentNotFound)
        }
        
        return ProductPerformance(
            productId: doc.documentID,
            name: data["name"] as? String ?? "",
            totalSold: data["totalSold"] as? Int ?? 0,
            revenue: data["revenue"] as? Double ?? 0,
            profit: data["profit"] as? Double ?? 0,
            averageRating: data["averageRating"] as? Double ?? 0,
            returnRate: data["returnRate"] as? Double ?? 0
        )
    }
    
    func getProductCategoryAnalytics() async throws -> [CategoryAnalytics] {
        let snapshot = try await db.collection("categories").getDocuments()
        return snapshot.documents.compactMap { doc -> CategoryAnalytics? in
            let data = doc.data()
            return CategoryAnalytics(
                category: doc.documentID,
                totalSales: data["totalSales"] as? Double ?? 0,
                itemsSold: data["itemsSold"] as? Int ?? 0,
                profitMargin: data["profitMargin"] as? Double ?? 0
            )
        }
    }
    
    func getLowPerformingProducts(threshold: Double) async throws -> [ProductPerformance] {
        let snapshot = try await db.collection("menu_items")
            .whereField("performance_score", isLessThan: threshold)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> ProductPerformance? in
            let data = doc.data()
            return ProductPerformance(
                productId: doc.documentID,
                name: data["name"] as? String ?? "",
                totalSold: data["totalSold"] as? Int ?? 0,
                revenue: data["revenue"] as? Double ?? 0,
                profit: data["profit"] as? Double ?? 0,
                averageRating: data["averageRating"] as? Double ?? 0,
                returnRate: data["returnRate"] as? Double ?? 0
            )
        }
    }
    
    // MARK: - Employee Analytics
    func getEmployeePerformance(employeeId: String) async throws -> EmployeePerformance {
        let doc = try await db.collection("employees").document(employeeId).getDocument()
        guard let data = doc.data() else {
            throw AppError.database(.documentNotFound)
        }
        
        return EmployeePerformance(
            employeeId: doc.documentID,
            name: data["name"] as? String ?? "",
            ordersProcessed: data["ordersProcessed"] as? Int ?? 0,
            totalSales: data["totalSales"] as? Double ?? 0,
            averageOrderTime: data["averageOrderTime"] as? TimeInterval ?? 0,
            customerRating: data["customerRating"] as? Double ?? 0
        )
    }
    
    func getStaffEfficiencyReport() async throws -> StaffEfficiencyReport {
        let snapshot = try await db.collection("staff_efficiency").getDocuments()
        guard let doc = snapshot.documents.first,
              let data = doc.data() as? [String: Any] else {
            throw AppError.database(.documentNotFound)
        }
        
        return StaffEfficiencyReport(
            averageOrderProcessingTime: data["averageOrderProcessingTime"] as? TimeInterval ?? 0,
            peakHourEfficiency: data["peakHourEfficiency"] as? Double ?? 0,
            staffUtilization: data["staffUtilization"] as? Double ?? 0,
            recommendedStaffing: data["recommendedStaffing"] as? [Int: Int] ?? [:]
        )
    }
    
    // MARK: - Event Tracking
//    func logEvent(_ event: AnalyticsEvent) {
//        analytics.logEvent(event.name, parameters: event.parameters)
//        
//        // Also save to Firestore for our own analytics
//        Task {
//            do {
//                try await db.collection("events").addDocument(data: [
//                    "name": event.name,
//                    "parameters": event.parameters,
//                    "timestamp": event.timestamp
//                ])
//            } catch {
//                print("Error saving event to Firestore: \(error)")
//            }
//        }
//    }
    
    func getEventStats(eventName: String, from: Date, to: Date) async throws -> EventStats {
        let snapshot = try await db.collection("events")
            .whereField("name", isEqualTo: eventName)
            .whereField("timestamp", isGreaterThanOrEqualTo: from)
            .whereField("timestamp", isLessThan: to)
            .getDocuments()
        
        return try processEventStats(from: snapshot.documents, eventName: eventName)
    }
    
    // MARK: - Helper Methods
    private func getDateRange(for period: AnalyticsPeriod) -> (Date, Calendar.Component) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .day:
            return (calendar.startOfDay(for: now), .hour)
        case .week:
            let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now)!
            return (startOfWeek, .day)
        case .month:
            let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            return (startOfMonth, .day)
        case .quarter:
            let startOfQuarter = calendar.date(byAdding: .month, value: -3, to: now)!
            return (startOfQuarter, .month)
        case .year:
            let startOfYear = calendar.date(byAdding: .year, value: -1, to: now)!
            return (startOfYear, .month)
        }
    }
    
    private func processDailySales(from documents: [QueryDocumentSnapshot], for date: Date) throws -> DailySales {
        var totalSales = 0.0
        let totalOrders = documents.count
        var peakHours: [Int: Int] = [:]
        var paymentMethods: [String: Int] = [:]
        
        for doc in documents {
            if let sale = try? doc.data(as: Sale.self) {
                totalSales += sale.total
                
                let hour = Calendar.current.component(.hour, from: sale.date)
                peakHours[hour, default: 0] += 1
                paymentMethods[sale.paymentMethod, default: 0] += 1
            }
        }
        
        let averageOrderValue = totalOrders > 0 ? totalSales / Double(totalOrders) : 0
        
        return DailySales(
            date: date,
            totalSales: totalSales,
            totalOrders: totalOrders,
            averageOrderValue: averageOrderValue,
            peakHours: peakHours,
            paymentMethods: paymentMethods
        )
    }
    
    private func processSalesReport(
        from documents: [QueryDocumentSnapshot],
        startDate: Date,
        endDate: Date
    ) async throws -> SalesReport {
        var totalRevenue = 0.0
        var totalOrders = 0
        var salesByDay: [Date: Double] = [:]
        var salesByCategory: [String: Double] = [:]
        
        for doc in documents {
            if let sale = try? doc.data(as: Sale.self) {
                totalRevenue += sale.total
                totalOrders += 1
                
                // Group by day
                let day = Calendar.current.startOfDay(for: sale.date)
                salesByDay[day, default: 0] += sale.total
                
                // Group by category
                for item in sale.items {
                    salesByCategory[item.category, default: 0] += item.total
                }
            }
        }
        
        let averageOrderValue = totalOrders > 0 ? totalRevenue / Double(totalOrders) : 0
        
        // Calculate comparison with previous period
        let previousStartDate = Calendar.current.date(
            byAdding: .day,
            value: -Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!,
            to: startDate
        )!
        
        let previousSnapshot = try? await db.collection("sales")
            .whereField("date", isGreaterThanOrEqualTo: previousStartDate)
            .whereField("date", isLessThan: startDate)
            .getDocuments()
        
        let previousRevenue = (try? calculateTotalRevenue(from: previousSnapshot?.documents ?? [])) ?? 0
        let comparisonWithPreviousPeriod = previousRevenue > 0 ?
            ((totalRevenue - previousRevenue) / previousRevenue) * 100 : 0
        
        return SalesReport(
            startDate: startDate,
            endDate: endDate,
            totalRevenue: totalRevenue,
            totalOrders: totalOrders,
            averageOrderValue: averageOrderValue,
            salesByDay: salesByDay,
            salesByCategory: salesByCategory,
            comparisonWithPreviousPeriod: comparisonWithPreviousPeriod
        )
    }
    
    private func processSalesTrend(
        from documents: [QueryDocumentSnapshot],
        interval: Calendar.Component
    ) throws -> [SalesTrendPoint] {
        var points: [SalesTrendPoint] = []
        var previousValue: Double?
        
        let groupedSales = Dictionary(grouping: documents) { doc -> Date in
            if let date = doc.data()["date"] as? Date {
                return Calendar.current.date(
                    bySetting: .minute,
                    value: 0,
                    of: Calendar.current.date(
                        bySetting: .second,
                        value: 0,
                        of: date
                    )!
                )!
            }
            return Date()
        }
        
        for (date, docs) in groupedSales.sorted(by: { $0.key < $1.key }) {
            let value = try calculateTotalRevenue(from: docs)
            
            let trend: TrendDirection
            if let previous = previousValue {
                trend = value > previous ? .up : (value < previous ? .down : .stable)
            } else {
                trend = .stable
            }
            
            points.append(SalesTrendPoint(date: date, value: value, trend: trend))
            previousValue = value
        }
        
        return points
    }
    
    private func processCustomerStats(from documents: [QueryDocumentSnapshot]) throws -> CustomerStats {
        let totalCustomers = documents.count
        
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let newCustomers = documents.filter { doc in
            guard let createdAt = doc.data()["createdAt"] as? Date else { return false }
            return createdAt > thirtyDaysAgo
        }.count
        
        let returningCustomers = documents.filter { doc in
            guard let visits = doc.data()["visitCount"] as? Int else { return false }
            return visits > 1
        }.count
        
        let totalVisits = documents.reduce(0) { sum, doc in
            sum + (doc.data()["visitCount"] as? Int ?? 0)
        }
        
        let averageVisitFrequency = totalCustomers > 0 ?
            Double(totalVisits) / Double(totalCustomers) : 0
        
        return CustomerStats(
            totalCustomers: totalCustomers,
            newCustomers: newCustomers,
            returningCustomers: returningCustomers,
            averageVisitFrequency: averageVisitFrequency
        )
    }
    
    private func processEventStats(
        from documents: [QueryDocumentSnapshot],
        eventName: String
    ) throws -> EventStats {
        let totalOccurrences = documents.count
        var frequency: [Date: Int] = [:]
        var parameters: [String: [String: Int]] = [:]
        
        for doc in documents {
            let data = doc.data()
            
            // Group by day for frequency
            if let timestamp = data["timestamp"] as? Date {
                let day = Calendar.current.startOfDay(for: timestamp)
                frequency[day, default: 0] += 1
            }
            
            // Aggregate parameter values
            if let eventParams = data["parameters"] as? [String: Any] {
                for (key, value) in eventParams {
                    if parameters[key] == nil {
                        parameters[key] = [:]
                    }
                    let stringValue = String(describing: value)
                    parameters[key]?[stringValue, default: 0] += 1
                }
            }
        }
        
        return EventStats(
            eventName: eventName,
            totalOccurrences: totalOccurrences,
            frequency: frequency,
            parameters: parameters
        )
    }
    
    private func calculateTotalRevenue(from documents: [QueryDocumentSnapshot]) throws -> Double {
        documents.reduce(0) { sum, doc in
            sum + (doc.data()["total"] as? Double ?? 0)
        }
    }
    
    func logEvent(_ name: String, params: [String : Any]?) {
        
    }
}

// MARK: - Supporting Types
struct Sale: Codable {
    let id: String
    let date: Date
    let total: Double
    let paymentMethod: String
    let items: [SaleItem]
}

struct SaleItem: Codable {
    let id: String
    let name: String
    let category: String
    let quantity: Int
    let price: Double
    let total: Double
} 
