import Foundation
import FirebaseAnalytics
import FirebaseFirestore
import Combine

final class AnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Singleton
    static let shared = AnalyticsService()
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let analytics = Analytics.self
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [String: ListenerRegistration] = [:]
    
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
    
    // MARK: - Sales revenueRecord
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
    
    func getSalesTrend(period: revenueRecordPeriod) async throws -> [SalesTrendPoint] {
        let (startDate, interval) = getDateRange(for: period)
        
        let snapshot = try await db.collection("sales")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .order(by: "date")
            .getDocuments()
        
        return try processSalesTrend(from: snapshot.documents, interval: interval)
    }
    
    // MARK: - Customer revenueRecord
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
    
    // MARK: - Product revenueRecord
    func getProductPerformance(productId: String) async throws -> ProductPerformance {
        let doc = try await db.collection("menu_items").document(productId).getDocument()
        guard let data = doc.data() else {
            throw AppError.database(.invalidData)
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
    
    // MARK: - Employee revenueRecord
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
        guard let doc = snapshot.documents.first else {
            throw AppError.database(.documentNotFound)
        }
        
        let data = doc.data()
        
        return StaffEfficiencyReport(
            averageOrderProcessingTime: data["averageOrderProcessingTime"] as? TimeInterval ?? 0,
            peakHourEfficiency: data["peakHourEfficiency"] as? Double ?? 0,
            staffUtilization: data["staffUtilization"] as? Double ?? 0,
            recommendedStaffing: data["recommendedStaffing"] as? [Int: Int] ?? [:]
        )
    }
    
    // MARK: - Event Tracking
    func getEventStats(eventName: String, from: Date, to: Date) async throws -> EventStats {
        let snapshot = try await db.collection("events")
            .whereField("name", isEqualTo: eventName)
            .whereField("timestamp", isGreaterThanOrEqualTo: from)
            .whereField("timestamp", isLessThan: to)
            .getDocuments()
        
        return try processEventStats(from: snapshot.documents, eventName: eventName)
    }
    
    // MARK: - Revenue Records Methods
//    func getRevenueRecords(userId: String, shopId: String, from: Date, to: Date) async throws -> [RevenueRecord] {
//        let snapshot = try await db.collection("users")
//            .document(userId)
//            .collection("shops")
//            .document(shopId)
//            .collection("revenue")
//            .whereField("date", isGreaterThanOrEqualTo: from)
//            .whereField("date", isLessThan: to)
//            .order(by: "date", descending: true)
//            .getDocuments()
//        
//        return try snapshot.documents.map { try RevenueRecord.from($0) }
//    }
//    
//    func listenToRevenueRecords(userId: String, shopId: String, from: Date, to: Date, completion: @escaping (Result<[RevenueRecord], Error>) -> Void) -> ListenerRegistration {
//        let listener = db.collection("users")
//            .document(userId)
//            .collection("shops")
//            .document(shopId)
//            .collection("revenue")
//            .whereField("date", isGreaterThanOrEqualTo: from)
//            .whereField("date", isLessThan: to)
//            .order(by: "date", descending: true)
//            .addSnapshotListener { snapshot, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else {
//                    completion(.success([]))
//                    return
//                }
//                
//                do {
//                    let records = try documents.map { try RevenueRecord.from($0) }
//                    completion(.success(records))
//                } catch {
//                    completion(.failure(error))
//                }
//            }
//        
//        // Lưu listener để có thể remove sau này
//        let key = "revenue_\(userId)_\(shopId)"
//        listeners[key] = listener
//        
//        return listener
//    }
//    
//    func createRevenueRecord(_ record: RevenueRecord, userId: String, shopId: String) async throws {
//        try await db.collection("users")
//            .document(userId)
//            .collection("shops")
//            .document(shopId)
//            .collection("revenue")
//            .addDocument(data: record.documentData)
//    }
//    
//    func updateRevenueRecord(_ record: RevenueRecord, userId: String, shopId: String) async throws {
//        guard let recordId = record.id else {
//            throw AppError.database(.invalidData)
//        }
//        
//        try await db.collection("users")
//            .document(userId)
//            .collection("shops")
//            .document(shopId)
//            .collection("revenue")
//            .document(recordId)
//            .setData(record.documentData, merge: true)
//    }
//    
//    func removeRevenueRecordListener(userId: String, shopId: String) {
//        let key = "revenue_\(userId)_\(shopId)"
//        listeners[key]?.remove()
//        listeners.removeValue(forKey: key)
//    }
    
    // MARK: - Helper Methods
    private func getDateRange(for period: revenueRecordPeriod) -> (Date, Calendar.Component) {
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
    
    private func processSalesReport(from documents: [QueryDocumentSnapshot], startDate: Date, endDate: Date) async throws -> SalesReport {
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
    
    private func processSalesTrend(from documents: [QueryDocumentSnapshot], interval: Calendar.Component) throws -> [SalesTrendPoint] {
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
    
    private func processEventStats(from documents: [QueryDocumentSnapshot],eventName: String) throws -> EventStats {
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

struct revenueRecordMetrics {
    let totalRevenue: Double
    let totalOrders: Int
    let averageOrderValue: Double
    let topSellingItem: String
    let revenueChange: Double
    let ordersChange: Double
    let averageOrderChange: Double
}

struct revenueRecordInsight {
    let peakHours: String
    let peakHoursPercentage: Double
    let bestDay: String
    let bestDayDetail: String
    let newCustomers: Int
    let newCustomersChange: Double
    let returnRate: Double
    let returnRateChange: Double
}

extension AnalyticsService {
    // MARK: - revenueRecord View Data
    
    /// Lấy dữ liệu metrics cho dashboard
    func getAnalyticsMetrics(for timeFilter: TimeFilter) async throws -> revenueRecordMetrics {
        let (currentPeriod, previousPeriod) = getTimeFilterDateRanges(for: timeFilter)
        
        async let currentReport = getSalesReport(from: currentPeriod.start, to: currentPeriod.end)
        async let previousReport = getSalesReport(from: previousPeriod.start, to: previousPeriod.end)
        async let topItems = getTopSellingItems(limit: 1)
        
        let (current, previous, topSellingItems) = try await (currentReport, previousReport, topItems)
        
        let revenueChange = calculatePercentageChange(
            current: current.totalRevenue,
            previous: previous.totalRevenue
        )
        
        let ordersChange = calculatePercentageChange(
            current: Double(current.totalOrders),
            previous: Double(previous.totalOrders)
        )
        
        let avgOrderChange = calculatePercentageChange(
            current: current.averageOrderValue,
            previous: previous.averageOrderValue
        )
        
        return revenueRecordMetrics(
            totalRevenue: current.totalRevenue,
            totalOrders: current.totalOrders,
            averageOrderValue: current.averageOrderValue,
            topSellingItem: topSellingItems.first?.name ?? "",
            revenueChange: revenueChange,
            ordersChange: ordersChange,
            averageOrderChange: avgOrderChange
        )
    }
    
    /// Lấy dữ liệu insights cho dashboard
    func getAnalyticsInsights(for timeFilter: TimeFilter) async throws -> revenueRecordInsight {
        let (currentPeriod, previousPeriod) = getTimeFilterDateRanges(for: timeFilter)
        
        async let currentStats = getCustomerStats()
        async let previousStats = getCustomerStatsForPeriod(from: previousPeriod.start, to: previousPeriod.end)
        async let salesReport = getSalesReport(from: currentPeriod.start, to: currentPeriod.end)
        
        let (current, previous, report) = try await (currentStats, previousStats, salesReport)
        
        // Tính toán giờ cao điểm
        let (peakHour, percentage) = calculatePeakHours(from: report)
        
        // Tính ngày tốt nhất
        let (bestDay, detail) = calculateBestDay(from: report)
        
        let newCustomersChange = calculatePercentageChange(
            current: Double(current.newCustomers),
            previous: Double(previous.newCustomers)
        )
        
        let returnRateChange = calculatePercentageChange(
            current: Double(current.returningCustomers) / Double(current.totalCustomers),
            previous: Double(previous.returningCustomers) / Double(previous.totalCustomers)
        )
        
        return revenueRecordInsight(
            peakHours: peakHour,
            peakHoursPercentage: percentage,
            bestDay: bestDay,
            bestDayDetail: detail,
            newCustomers: current.newCustomers,
            newCustomersChange: newCustomersChange,
            returnRate: Double(current.returningCustomers) / Double(current.totalCustomers) * 100,
            returnRateChange: returnRateChange
        )
    }
    
    /// Lấy dữ liệu revenue theo thời gian
//    func getRevenueData(for timeFilter: TimeFilter) async throws -> [RevenueData] {
//        let (period, _) = getTimeFilterDateRanges(for: timeFilter)
//        let salesTrend = try await getSalesTrend(period: convertTimeFilterToAnalyticsPeriod(timeFilter))
//        
//        return salesTrend.map { point in
//            RevenueData(date: point.date, revenue: point.value)
//        }
//    }
    
    // MARK: - Helper Methods
    private func getTimeFilterDateRanges(for filter: TimeFilter) -> (current: (start: Date, end: Date), previous: (start: Date, end: Date)) {
        let calendar = Calendar.current
        let now = Date()
        
        var currentStart: Date
        var currentEnd = now
        
        switch filter {
        case .day:
            currentStart = calendar.startOfDay(for: now)
        case .week:
            currentStart = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            currentStart = calendar.date(byAdding: .month, value: -1, to: now)!
        }
        
        let periodLength = calendar.dateComponents([.second], from: currentStart, to: currentEnd).second!
        let previousEnd = currentStart
        let previousStart = calendar.date(byAdding: .second, value: -periodLength, to: previousEnd)!
        
        return (
            current: (start: currentStart, end: currentEnd),
            previous: (start: previousStart, end: previousEnd)
        )
    }
    
    private func calculatePercentageChange(current: Double, previous: Double) -> Double {
        guard previous != 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    
    private func calculatePeakHours(from report: SalesReport) -> (hours: String, percentage: Double) {
        // Giả sử report có thông tin về số đơn hàng theo giờ
        let peakHour = "7:00 - 9:00 AM" // Implement logic to find actual peak hours
        let percentage = 35.0 // Implement logic to calculate actual percentage
        return (peakHour, percentage)
    }
    
    private func calculateBestDay(from report: SalesReport) -> (day: String, detail: String) {
        // Implement logic to find the best performing day
        return ("Thứ 6", "Doanh thu cao nhất tuần")
    }
    
    private func convertTimeFilterToAnalyticsPeriod(_ filter: TimeFilter) -> revenueRecordPeriod {
        switch filter {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        }
    }
    
    private func getCustomerStatsForPeriod(from: Date, to: Date) async throws -> CustomerStats {
        // Implement logic to get customer stats for a specific period
        let snapshot = try await db.collection("customers")
            .whereField("createdAt", isGreaterThanOrEqualTo: from)
            .whereField("createdAt", isLessThan: to)
            .getDocuments()
        
        return try processCustomerStats(from: snapshot.documents)
    }
}

// Add TimeFilter enum if not already defined elsewhere
enum TimeFilter: CaseIterable {
    case day, week, month
    
    var displayName: String {
        switch self {
        case .day: return "Ngày"
        case .week: return "Tuần"
        case .month: return "Tháng"
        }
    }
    
    var chartDescription: String {
        switch self {
        case .day: return "24 giờ qua"
        case .week: return "7 ngày qua"
        case .month: return "4 tuần qua"
        }
    }
    
    var axisStride: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week: return .day
        case .month: return .weekOfYear
        }
    }
}
