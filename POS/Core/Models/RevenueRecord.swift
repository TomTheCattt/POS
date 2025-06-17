import Foundation
import FirebaseFirestore

// Struct để lưu trữ thông tin một khoản thu chi
struct ExpenseItem: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let shopId: String // ID của cửa hàng
    let amount: Double // Số tiền (dương là thu, âm là chi)
    let description: String // Mô tả khoản thu chi
    let category: ExpenseCategory // Phân loại khoản thu chi
    let expenseDate: Date // Ngày phát sinh thu chi
    let isRecurring: Bool // Có phải khoản thu chi định kỳ không
    let recurringType: RecurringType? // Loại định kỳ (tháng/quý/năm)
    var status: ExpenseStatus // Trạng thái của khoản thu chi
    var attachmentUrls: [String] // URL của các chứng từ đính kèm
    let createdBy: String // ID của người tạo
    let createdAt: Date
    var updatedAt: Date
    var approvedBy: String? // ID của người duyệt (nếu có)
    var approvedAt: Date? // Thời điểm duyệt
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case utilities // Tiện ích (điện, nước, internet...)
    case inventory // Nhập hàng
    case salary // Lương nhân viên
    case rent // Tiền thuê mặt bằng
    case equipment // Thiết bị, dụng cụ
    case marketing // Marketing, quảng cáo
    case maintenance // Bảo trì, sửa chữa
    case other // Khác
}

enum RecurringType: String, Codable, CaseIterable {
    case monthly // Hàng tháng
    case quarterly // Hàng quý
    case yearly // Hàng năm
    
    var displayTitle: String {
        switch self {
        case .monthly:
            return "Hàng tháng"
        case .quarterly:
            return "Hàng quý"
        case .yearly:
            return "Hàng năm"
        }
    }
}

enum ExpenseStatus: String, Codable {
    case pending // Chờ duyệt
    case approved // Đã duyệt
    case rejected // Từ chối
    case cancelled // Đã hủy
}

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
    
//    init(id: String? = nil,
//         shopId: String,
//         date: Date,
//         revenue: Double,
//         totalOrders: Int,
//         averageOrderValue: Double,
//         topSellingItems: [String: Int],
//         peakHours: [Int: Double],
//         dayOfWeekRevenue: [Int: Double],
//         newCustomers: Int,
//         returningCustomers: Int,
//         totalCustomers: Int,
//         paymentMethods: [String: Int] = [:],
//         createdAt: Date = Date(),
//         updatedAt: Date = Date()) {
//        self.id = id
//        self.shopId = shopId
//        self.date = date
//        self.revenue = revenue
//        self.totalOrders = totalOrders
//        self.averageOrderValue = averageOrderValue
//        self.topSellingItems = topSellingItems
//        self.peakHours = peakHours
//        self.dayOfWeekRevenue = dayOfWeekRevenue
//        self.newCustomers = newCustomers
//        self.returningCustomers = returningCustomers
//        self.totalCustomers = totalCustomers
//        self.paymentMethods = paymentMethods
//        self.createdAt = createdAt
//        self.updatedAt = updatedAt
//    }
    
//    var dictionary: [String: Any] {
//        [
//            "id": id as Any,
//            "shopId": shopId,
//            "date": Timestamp(date: date),
//            "revenue": revenue,
//            "totalOrders": totalOrders,
//            "averageOrderValue": averageOrderValue,
//            "topSellingItems": topSellingItems,
//            "peakHours": peakHours,
//            "dayOfWeekRevenue": dayOfWeekRevenue,
//            "newCustomers": newCustomers,
//            "returningCustomers": returningCustomers,
//            "totalCustomers": totalCustomers,
//            "paymentMethods": paymentMethods,
//            "createdAt": Timestamp(date: createdAt),
//            "updatedAt": Timestamp(date: updatedAt)
//        ]
//    }
}

//extension RevenueRecord {
//    init?(document: DocumentSnapshot) {
//        guard let data = document.data(),
//            let shopId = data["shopId"] as? String,
//              let date = (data["date"] as? Timestamp)?.dateValue(),
//              let revenue = data["revenue"] as? Double,
//              let totalOrders = data["totalOrders"] as? Int,
//              let averageOrderValue = data["averageOrderValue"] as? Double,
//              let topSellingItems = data["topSellingItems"] as? [String: Int],
//              let peakHours = data["peakHours"] as? [String: Double],
//              let dayOfWeekRevenue = data["dayOfWeekRevenue"] as? [String: Double],
//              let newCustomers = data["newCustomers"] as? Int,
//              let returningCustomers = data["returningCustomers"] as? Int,
//              let totalCustomers = data["totalCustomers"] as? Int,
//              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
//              let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
//        else {
//            return nil
//        }
//        
//        // Convert String keys to Int for peakHours and dayOfWeekRevenue
//        let peakHoursWithIntKeys = Dictionary(uniqueKeysWithValues: peakHours.map { (Int($0.key) ?? 0, $0.value) })
//        let dayOfWeekRevenueWithIntKeys = Dictionary(uniqueKeysWithValues: dayOfWeekRevenue.map { (Int($0.key) ?? 0, $0.value) })
//        
//        // Get payment methods if available
//        let paymentMethods = data["paymentMethods"] as? [String: Int] ?? [:]
//        
//        self.init(
//            id: document.documentID,
//            shopId: shopId,
//            date: date,
//            revenue: revenue,
//            totalOrders: totalOrders,
//            averageOrderValue: averageOrderValue,
//            topSellingItems: topSellingItems,
//            peakHours: peakHoursWithIntKeys,
//            dayOfWeekRevenue: dayOfWeekRevenueWithIntKeys,
//            newCustomers: newCustomers,
//            returningCustomers: returningCustomers,
//            totalCustomers: totalCustomers,
//            paymentMethods: paymentMethods,
//            createdAt: createdAt,
//            updatedAt: updatedAt
//        )
//    }
//} 
