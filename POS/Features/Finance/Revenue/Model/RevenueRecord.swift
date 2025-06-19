import Foundation
import FirebaseFirestore
import SwiftUI

struct RevenueRecord: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    let shopId: String
    let date: Date
    var revenue: Double
    var totalOrders: Int
    var averageOrderValue: Double
    
    // Thu chi trong ngày của cửa hàng
    var expenseIds: [String] = [] // Danh sách ID của các khoản thu chi trong ngày
    
    // Computed properties sẽ được tính toán từ ViewModel
    // vì cần query từ ExpenseItems collection
    
    // Chi tiết theo sản phẩm
    var topSellingItems: [String: Int] // [productId: quantity]
    
    // Thông tin thời gian
    var peakHours: [Int: Double] // [hour: revenue]
    var dayOfWeekRevenue: [Int: Double] // [dayOfWeek: revenue]
    
    // Thông tin khách hàng
    var newCustomers: Int
    var returningCustomers: Int
    
    // Thông tin phương thức thanh toán
    var paymentMethods: [String: Int] // [paymentMethod.rawValue: count]
    
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        shopId: String,
        date: Date,
        revenue: Double = 0.0,
        totalOrders: Int = 0,
        averageOrderValue: Double = 0.0,
        expenseIds: [String] = [],
        topSellingItems: [String: Int] = [:],
        peakHours: [Int: Double] = [:],
        dayOfWeekRevenue: [Int: Double] = [:],
        newCustomers: Int = 0,
        returningCustomers: Int = 0,
        paymentMethods: [String: Int] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.shopId = shopId
        self.date = date
        self.revenue = revenue
        self.totalOrders = totalOrders
        self.averageOrderValue = averageOrderValue
        self.expenseIds = expenseIds
        self.topSellingItems = topSellingItems
        self.peakHours = peakHours
        self.dayOfWeekRevenue = dayOfWeekRevenue
        self.newCustomers = newCustomers
        self.returningCustomers = returningCustomers
        self.paymentMethods = paymentMethods
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    var formattedRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: revenue)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    var formattedAverageOrderValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: averageOrderValue)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.weekdaySymbols = ["Chủ nhật", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"]
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yyyy"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    var isThisWeek: Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var isThisMonth: Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    var profitMargin: Double {
        // This would need to be calculated from expenses
        // For now, return a placeholder
        return 0.0
    }
    
    var formattedProfitMargin: String {
        return String(format: "%.1f%%", profitMargin)
    }
    
    var topSellingItemsList: [(name: String, quantity: Int)] {
        return topSellingItems.sorted { $0.value > $1.value }.map { (name: $0.key, quantity: $0.value) }
    }
    
    var peakHoursList: [(hour: Int, revenue: Double)] {
        return peakHours.sorted { $0.key < $1.key }.map { (hour: $0.key, revenue: $0.value) }
    }
    
    var paymentMethodsList: [(method: String, count: Int)] {
        return paymentMethods.sorted { $0.value > $1.value }.map { (method: $0.key, count: $0.value) }
    }
    
    var mostPopularPaymentMethod: String? {
        return paymentMethods.max(by: { $0.value < $1.value })?.key
    }
    
    var peakHour: Int? {
        return peakHours.max(by: { $0.value < $1.value })?.key
    }
    
    var formattedPeakHour: String {
        guard let peakHour = peakHour else { return "N/A" }
        return String(format: "%02d:00", peakHour)
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "shopId": shopId,
            "date": Timestamp(date: date),
            "revenue": revenue,
            "totalOrders": totalOrders,
            "averageOrderValue": averageOrderValue,
            "expenseIds": expenseIds,
            "topSellingItems": topSellingItems,
            "peakHours": peakHours,
            "dayOfWeekRevenue": dayOfWeekRevenue,
            "newCustomers": newCustomers,
            "returningCustomers": returningCustomers,
            "paymentMethods": paymentMethods,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let shopId = dictionary["shopId"] as? String,
              let dateTimestamp = dictionary["date"] as? Timestamp,
              let revenue = dictionary["revenue"] as? Double,
              let totalOrders = dictionary["totalOrders"] as? Int,
              let averageOrderValue = dictionary["averageOrderValue"] as? Double,
              let expenseIds = dictionary["expenseIds"] as? [String],
              let topSellingItems = dictionary["topSellingItems"] as? [String: Int],
              let peakHours = dictionary["peakHours"] as? [Int: Double],
              let dayOfWeekRevenue = dictionary["dayOfWeekRevenue"] as? [Int: Double],
              let newCustomers = dictionary["newCustomers"] as? Int,
              let returningCustomers = dictionary["returningCustomers"] as? Int,
              let paymentMethods = dictionary["paymentMethods"] as? [String: Int],
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        self.init(
            shopId: shopId,
            date: dateTimestamp.dateValue(),
            revenue: revenue,
            totalOrders: totalOrders,
            averageOrderValue: averageOrderValue,
            expenseIds: expenseIds,
            topSellingItems: topSellingItems,
            peakHours: peakHours,
            dayOfWeekRevenue: dayOfWeekRevenue,
            newCustomers: newCustomers,
            returningCustomers: returningCustomers,
            paymentMethods: paymentMethods,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
    
    // MARK: - Mutating Methods
    mutating func updateRevenue(_ newRevenue: Double) {
        revenue = newRevenue
        updatedAt = Date()
    }
    
    mutating func updateTotalOrders(_ newTotalOrders: Int) {
        totalOrders = newTotalOrders
        updatedAt = Date()
    }
    
    mutating func updateAverageOrderValue(_ newAverageOrderValue: Double) {
        averageOrderValue = newAverageOrderValue
        updatedAt = Date()
    }
    
    mutating func addExpenseId(_ expenseId: String) {
        if !expenseIds.contains(expenseId) {
            expenseIds.append(expenseId)
            updatedAt = Date()
        }
    }
    
    mutating func removeExpenseId(_ expenseId: String) {
        expenseIds.removeAll { $0 == expenseId }
        updatedAt = Date()
    }
    
    mutating func updateTopSellingItems(_ newTopSellingItems: [String: Int]) {
        topSellingItems = newTopSellingItems
        updatedAt = Date()
    }
    
    mutating func updatePeakHours(_ newPeakHours: [Int: Double]) {
        peakHours = newPeakHours
        updatedAt = Date()
    }
    
    mutating func updateDayOfWeekRevenue(_ newDayOfWeekRevenue: [Int: Double]) {
        dayOfWeekRevenue = newDayOfWeekRevenue
        updatedAt = Date()
    }
    
    mutating func updateCustomerStats(newCustomers: Int, returningCustomers: Int, totalCustomers: Int) {
        self.newCustomers = newCustomers
        self.returningCustomers = returningCustomers
        updatedAt = Date()
    }
    
    mutating func updatePaymentMethods(_ newPaymentMethods: [String: Int]) {
        paymentMethods = newPaymentMethods
        updatedAt = Date()
    }
    
    // MARK: - Helper Methods
    func getRevenueForHour(_ hour: Int) -> Double {
        return peakHours[hour] ?? 0.0
    }
    
    func getRevenueForDayOfWeek(_ dayOfWeek: Int) -> Double {
        return dayOfWeekRevenue[dayOfWeek] ?? 0.0
    }
    
    func getQuantityForItem(_ itemName: String) -> Int {
        return topSellingItems[itemName] ?? 0
    }
    
    func getPaymentMethodCount(_ method: String) -> Int {
        return paymentMethods[method] ?? 0
    }
    
    func hasExpense(_ expenseId: String) -> Bool {
        return expenseIds.contains(expenseId)
    }
    
    func calculateProfit(expenses: [String: Double]) -> Double {
        let totalExpenses = expenseIds.reduce(0) { total, expenseId in
            total + (expenses[expenseId] ?? 0)
        }
        return revenue - totalExpenses
    }
    
    func calculateProfitMargin(expenses: [String: Double]) -> Double {
        let profit = calculateProfit(expenses: expenses)
        guard revenue > 0 else { return 0 }
        return (profit / revenue) * 100
    }
}

// MARK: - Comparable
extension RevenueRecord: Comparable {
    static func < (lhs: RevenueRecord, rhs: RevenueRecord) -> Bool {
        return lhs.date < rhs.date
    }
}

// MARK: - Validation
extension RevenueRecord {
    enum ValidationError: LocalizedError {
        case invalidRevenue
        case invalidTotalOrders
        case invalidAverageOrderValue
        case invalidCustomerStats
        case invalidDate
        
        var errorDescription: String? {
            switch self {
            case .invalidRevenue:
                return "Doanh thu không hợp lệ"
            case .invalidTotalOrders:
                return "Tổng số đơn hàng không hợp lệ"
            case .invalidAverageOrderValue:
                return "Giá trị đơn hàng trung bình không hợp lệ"
            case .invalidCustomerStats:
                return "Thống kê khách hàng không hợp lệ"
            case .invalidDate:
                return "Ngày không hợp lệ"
            }
        }
    }
    
    func validate() throws {
        // Validate revenue
        guard revenue >= 0 else {
            throw ValidationError.invalidRevenue
        }
        
        guard revenue <= 1000000000 else { // Max 1 billion VND
            throw ValidationError.invalidRevenue
        }
        
        // Validate total orders
        guard totalOrders >= 0 else {
            throw ValidationError.invalidTotalOrders
        }
        
        guard totalOrders <= 10000 else { // Max 10,000 orders per day
            throw ValidationError.invalidTotalOrders
        }
        
        // Validate average order value
        guard averageOrderValue >= 0 else {
            throw ValidationError.invalidAverageOrderValue
        }
        
        guard averageOrderValue <= 10000000 else { // Max 10 million VND per order
            throw ValidationError.invalidAverageOrderValue
        }
        
        // Validate customer stats
        guard newCustomers >= 0 && returningCustomers >= 0 else {
            throw ValidationError.invalidCustomerStats
        }
        
        // Validate date
        let calendar = Calendar.current
        let now = Date()
        let daysDifference = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        
        guard daysDifference >= -1 && daysDifference <= 365 else { // Allow future date (1 day) and past year
            throw ValidationError.invalidDate
        }
    }
}

// MARK: - Revenue Analytics
extension RevenueRecord {
    static func calculateTotalRevenue(_ records: [RevenueRecord]) -> Double {
        return records.reduce(0) { $0 + $1.revenue }
    }
    
    static func calculateAverageDailyRevenue(_ records: [RevenueRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        return calculateTotalRevenue(records) / Double(records.count)
    }
    
    static func calculateRevenueGrowth(_ currentRecords: [RevenueRecord], previousRecords: [RevenueRecord]) -> Double {
        let currentRevenue = calculateTotalRevenue(currentRecords)
        let previousRevenue = calculateTotalRevenue(previousRecords)
        
        guard previousRevenue > 0 else { return 0 }
        return ((currentRevenue - previousRevenue) / previousRevenue) * 100
    }
    
    static func getTopSellingItems(_ records: [RevenueRecord]) -> [String: Int] {
        var itemCounts: [String: Int] = [:]
        
        for record in records {
            for (item, quantity) in record.topSellingItems {
                itemCounts[item, default: 0] += quantity
            }
        }
        
        return itemCounts
    }
    
    static func getPeakHours(_ records: [RevenueRecord]) -> [Int: Double] {
        var hourRevenue: [Int: Double] = [:]
        
        for record in records {
            for (hour, revenue) in record.peakHours {
                hourRevenue[hour, default: 0] += revenue
            }
        }
        
        return hourRevenue
    }
}
