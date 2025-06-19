import Foundation
import FirebaseFirestore

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
