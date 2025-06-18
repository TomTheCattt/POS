import Foundation
import FirebaseFirestore

struct RevenueRecord: Identifiable, Codable, Equatable {
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
    var totalCustomers: Int
    
    // Thông tin phương thức thanh toán
    var paymentMethods: [String: Int] // [paymentMethod.rawValue: count]
    
    let createdAt: Date
    var updatedAt: Date
}
