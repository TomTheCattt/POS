//
//  Shop.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation
import FirebaseFirestore

enum Currency: String, Codable {
    case vnd = "VND"
    case usd = "USD"
    
    var symbol: String {
        switch self {
        case .vnd: return "đ"
        case .usd: return "$"
        }
    }
}

struct DiscountVoucher: Codable, Equatable, Hashable {
    let name: String
    let value: Double
    
    var dictionary: [String: Any] {
        [
            "name": name,
            "value": value
        ]
    }
    
    init(name: String, value: Double) {
        self.name = name
        self.value = value
    }
    
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let value = dictionary["value"] as? Double else { return nil }
        self.init(
            name: name,
            value: value
        )
    }
}

struct BusinessHours: Codable, Equatable, Hashable {
    let openHour: Int
    let openMinute: Int
    let closeHour: Int
    let closeMinute: Int
    
    init(open: Date, close: Date) {
        let calendar = Calendar.current
        let openComponents = calendar.dateComponents([.hour, .minute], from: open)
        let closeComponents = calendar.dateComponents([.hour, .minute], from: close)

        self.openHour = openComponents.hour ?? 0
        self.openMinute = openComponents.minute ?? 0
        self.closeHour = closeComponents.hour ?? 0
        self.closeMinute = closeComponents.minute ?? 0
    }

    // MARK: - Helpers

    var openTime: Date {
        var components = DateComponents()
        components.hour = openHour
        components.minute = openMinute
        return Calendar.current.date(from: components)!
    }

    var closeTime: Date {
        var components = DateComponents()
        components.hour = closeHour
        components.minute = closeMinute
        return Calendar.current.date(from: components)!
    }

    /// Dải giờ mở cửa dưới dạng array Int (giờ): [8, 9, 10, ..., 17]
    var hoursRange: [Int] {
        let open = openHour
        let close = closeHour

        if close > open {
            return Array(open..<close)
        } else {
            // Ví dụ 22h đến 2h sáng hôm sau → [22, 23, 0, 1]
            return Array(open...23) + Array(0..<close)
        }
    }

    var businessHoursFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: openTime)) - \(formatter.string(from: closeTime))"
    }
}

struct Shop: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Constants
    static let maxShopsPerUser = 4
    
    // MARK: - Properties
    @DocumentID var id: String?
    var shopName: String
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    let ownerId: String
    var groundRent: Double
    var currency: Currency
    var address: String
    var businessHours: BusinessHours
    var discountVouchers: [DiscountVoucher]?
    var pointRate: Double
    
    // MARK: - Computed Properties
    var formattedGroundRent: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: groundRent)) ?? "0"
        return "\(formattedNumber)\(currency.symbol)/tháng"
    }
    
    static func < (lhs: Shop, rhs: Shop) -> Bool {
        return lhs.shopName < rhs.shopName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(shopName)
        hasher.combine(isActive)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
        hasher.combine(createdAt)
        hasher.combine(ownerId)
        hasher.combine(groundRent)
        hasher.combine(currency)
        hasher.combine(address)
        hasher.combine(businessHours)
        hasher.combine(discountVouchers)
        hasher.combine(pointRate)
    }
}

// MARK: - Validation
extension Shop {
    enum ValidationError: LocalizedError {
        case exceedMaxShopsLimit
        case invalidShopName
        case invalidGroundRent
        
        var errorDescription: String? {
            switch self {
            case .exceedMaxShopsLimit:
                return "Bạn đã đạt giới hạn tối đa \(Shop.maxShopsPerUser) cửa hàng"
            case .invalidShopName:
                return "Tên cửa hàng không hợp lệ"
            case .invalidGroundRent:
                return "Chi phí mặt bằng không hợp lệ"
            }
        }
    }
    
    static func validate(shopName: String, groundRent: Double, ownerId: String, existingShops: [Shop]) throws {
        // Validate shop name
        guard !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidShopName
        }
        
        // Validate ground rent
        guard groundRent >= 0 else {
            throw ValidationError.invalidGroundRent
        }
        
        // Validate max shops limit
        let userShops = existingShops.filter { $0.ownerId == ownerId }
        guard userShops.count < maxShopsPerUser else {
            throw ValidationError.exceedMaxShopsLimit
        }
    }
}

