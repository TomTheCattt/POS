import Foundation
import Combine

// MARK: - Supporting Types
struct DailySales: Codable {
    let date: Date
    let totalSales: Double
    let totalOrders: Int
    let averageOrderValue: Double
    let peakHours: [Int: Int]
    let paymentMethods: [String: Int]
}

struct SalesReport: Codable {
    let startDate: Date
    let endDate: Date
    let totalRevenue: Double
    let totalOrders: Int
    let averageOrderValue: Double
    let salesByDay: [Date: Double]
    let salesByCategory: [String: Double]
    let comparisonWithPreviousPeriod: Double
}

struct TopSellingItem: Codable {
    let itemId: String
    let name: String
    let quantity: Int
    let revenue: Double
    let profit: Double
}

struct SalesTrendPoint: Codable {
    let date: Date
    let value: Double
    let trend: TrendDirection
}

enum TrendDirection: String, Codable {
    case up
    case down
    case stable
}

struct CustomerStats: Codable {
    let totalCustomers: Int
    let newCustomers: Int
    let returningCustomers: Int
    let averageVisitFrequency: Double
}

struct ProductPerformance: Codable {
    let productId: String
    let name: String
    let totalSold: Int
    let revenue: Double
    let profit: Double
    let averageRating: Double
    let returnRate: Double
}

struct CategoryAnalytics: Codable {
    let category: String
    let totalSales: Double
    let itemsSold: Int
    let profitMargin: Double
}

struct EmployeePerformance: Codable {
    let employeeId: String
    let name: String
    let ordersProcessed: Int
    let totalSales: Double
    let averageOrderTime: TimeInterval
    let customerRating: Double
}

struct StaffEfficiencyReport: Codable {
    let averageOrderProcessingTime: TimeInterval
    let peakHourEfficiency: Double
    let staffUtilization: Double
    let recommendedStaffing: [Int: Int]
}

enum revenueRecordPeriod: String {
    case day
    case week
    case month
    case quarter
    case year
}

//struct revenueRecordEvent: Codable {
//    let name: String
//    let parameters: [String: Any]
//    let timestamp: Date
//}

struct EventStats: Codable {
    let eventName: String
    let totalOccurrences: Int
    let frequency: [Date: Int]
    let parameters: [String: [String: Int]]
} 
