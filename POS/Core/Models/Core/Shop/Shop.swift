//
//  Shop.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation
import FirebaseFirestore

enum Currency: String, Codable, CaseIterable {
    case vnd = "VND"
    case usd = "USD"
    
    var symbol: String {
        switch self {
        case .vnd: return "đ"
        case .usd: return "$"
        }
    }
    
    var displayName: String {
        switch self {
        case .vnd: return "Việt Nam Đồng"
        case .usd: return "US Dollar"
        }
    }
    
    // MARK: - Currency Conversion
    static let vndToUsdRate: Double = 1.0 / 25000.0 // 1 USD = 25,000 VND
    static let usdToVndRate: Double = 25000.0
    
    func convertPrice(_ priceInVND: Double) -> Double {
        switch self {
        case .vnd:
            return priceInVND
        case .usd:
            return (priceInVND * Self.vndToUsdRate).rounded(to: 2)
        }
    }
    
    func convertPriceToVND(_ price: Double) -> Double {
        switch self {
        case .vnd:
            return price
        case .usd:
            return price * Self.usdToVndRate
        }
    }
    
    func formatPrice(_ price: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        
        switch self {
        case .vnd:
            numberFormatter.groupingSeparator = "."
            let formattedNumber = numberFormatter.string(from: NSNumber(value: price)) ?? "\(price)"
            return "\(formattedNumber)\(symbol)"
        case .usd:
            numberFormatter.groupingSeparator = ","
            let formattedNumber = numberFormatter.string(from: NSNumber(value: price)) ?? "\(price)"
            return "\(symbol)\(formattedNumber)"
        }
    }
}

// MARK: - Double Extension for Rounding
extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
    
    func roundedToThousands() -> Double {
        return (self / 1000.0).rounded() * 1000.0
    }
}

struct DiscountVoucher: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let value: Double
    let isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    
    var dictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "value": value,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    init(id: String = UUID().uuidString, name: String, value: Double, isActive: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.value = value
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let value = dictionary["value"] as? Double,
              let isActive = dictionary["isActive"] as? Bool,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else { 
            return nil 
        }
        
        self.init(
            id: id,
            name: name,
            value: value,
            isActive: isActive,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
    
    // MARK: - Firestore Codable Support
    enum CodingKeys: String, CodingKey {
        case id, name, value, isActive, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(Double.self, forKey: .value)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        
        // Handle Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
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
    
    init(openHour: Int, openMinute: Int, closeHour: Int, closeMinute: Int) {
        self.openHour = openHour
        self.openMinute = openMinute
        self.closeHour = closeHour
        self.closeMinute = closeMinute
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
    
    var isOpen: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        let openTimeInMinutes = openHour * 60 + openMinute
        let closeTimeInMinutes = closeHour * 60 + closeMinute
        
        if closeTimeInMinutes > openTimeInMinutes {
            return currentTimeInMinutes >= openTimeInMinutes && currentTimeInMinutes <= closeTimeInMinutes
        } else {
            // Handle overnight hours (e.g., 22:00 - 02:00)
            return currentTimeInMinutes >= openTimeInMinutes || currentTimeInMinutes <= closeTimeInMinutes
        }
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
    var pointRate: Double // Tỷ lệ tích điểm (5-10%)
    
    // MARK: - Computed Properties
    var formattedGroundRent: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: groundRent)) ?? "0"
        return "\(formattedNumber)\(currency.symbol)/tháng"
    }
    
    var isOpen: Bool {
        return isActive && businessHours.isOpen
    }
    
    var statusText: String {
        if !isActive {
            return "Tạm ngưng"
        } else if businessHours.isOpen {
            return "Đang mở cửa"
        } else {
            return "Đã đóng cửa"
        }
    }
    
    var statusColor: String {
        if !isActive {
            return "gray"
        } else if businessHours.isOpen {
            return "green"
        } else {
            return "red"
        }
    }
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        shopName: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        ownerId: String,
        groundRent: Double = 0.0,
        currency: Currency = .vnd,
        address: String = "",
        businessHours: BusinessHours,
        discountVouchers: [DiscountVoucher]? = nil,
        pointRate: Double = 0.0
    ) {
        self.id = id
        self.shopName = shopName
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerId = ownerId
        self.groundRent = groundRent
        self.currency = currency
        self.address = address
        self.businessHours = businessHours
        self.discountVouchers = discountVouchers
        self.pointRate = pointRate
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "shopName": shopName,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "ownerId": ownerId,
            "groundRent": groundRent,
            "currency": currency.rawValue,
            "address": address,
            "businessHours": [
                "openHour": businessHours.openHour,
                "openMinute": businessHours.openMinute,
                "closeHour": businessHours.closeHour,
                "closeMinute": businessHours.closeMinute
            ],
            "pointRate": pointRate
        ]
        
        if let vouchers = discountVouchers {
            dict["discountVouchers"] = vouchers.map { $0.dictionary }
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let shopName = dictionary["shopName"] as? String,
              let isActive = dictionary["isActive"] as? Bool,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp,
              let ownerId = dictionary["ownerId"] as? String,
              let groundRent = dictionary["groundRent"] as? Double,
              let currencyRaw = dictionary["currency"] as? String,
              let currency = Currency(rawValue: currencyRaw),
              let address = dictionary["address"] as? String,
              let businessHoursDict = dictionary["businessHours"] as? [String: Any],
              let pointRate = dictionary["pointRate"] as? Double else {
            return nil
        }
        
        // Parse BusinessHours
        guard let openHour = businessHoursDict["openHour"] as? Int,
              let openMinute = businessHoursDict["openMinute"] as? Int,
              let closeHour = businessHoursDict["closeHour"] as? Int,
              let closeMinute = businessHoursDict["closeMinute"] as? Int else {
            return nil
        }
        
        let businessHours = BusinessHours(
            openHour: openHour,
            openMinute: openMinute,
            closeHour: closeHour,
            closeMinute: closeMinute
        )
        
        // Parse DiscountVouchers
        var discountVouchers: [DiscountVoucher]?
        if let vouchersArray = dictionary["discountVouchers"] as? [[String: Any]] {
            discountVouchers = vouchersArray.compactMap { DiscountVoucher(dictionary: $0) }
        }
        
        self.init(
            shopName: shopName,
            isActive: isActive,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            ownerId: ownerId,
            groundRent: groundRent,
            currency: currency,
            address: address,
            businessHours: businessHours,
            discountVouchers: discountVouchers,
            pointRate: pointRate
        )
    }
    
    // MARK: - Mutating Methods
    mutating func updateShop(
        shopName: String? = nil,
        isActive: Bool? = nil,
        groundRent: Double? = nil,
        currency: Currency? = nil,
        address: String? = nil,
        businessHours: BusinessHours? = nil,
        discountVouchers: [DiscountVoucher]? = nil,
        pointRate: Double? = nil
    ) {
        if let shopName = shopName {
            self.shopName = shopName
        }
        if let isActive = isActive {
            self.isActive = isActive
        }
        if let groundRent = groundRent {
            self.groundRent = groundRent
        }
        if let currency = currency {
            self.currency = currency
        }
        if let address = address {
            self.address = address
        }
        if let businessHours = businessHours {
            self.businessHours = businessHours
        }
        if let discountVouchers = discountVouchers {
            self.discountVouchers = discountVouchers
        }
        if let pointRate = pointRate {
            self.pointRate = pointRate
        }
        
        self.updatedAt = Date()
    }
    
    mutating func toggleActive() {
        isActive.toggle()
        updatedAt = Date()
    }
    
    mutating func addDiscountVoucher(_ voucher: DiscountVoucher) {
        if discountVouchers == nil {
            discountVouchers = []
        }
        discountVouchers?.append(voucher)
        updatedAt = Date()
    }
    
    mutating func removeDiscountVoucher(at index: Int) {
        guard let vouchers = discountVouchers, index >= 0 && index < vouchers.count else { return }
        discountVouchers?.remove(at: index)
        updatedAt = Date()
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
        case invalidAddress
        case invalidBusinessHours
        case invalidPointRate
        
        var errorDescription: String? {
            switch self {
            case .exceedMaxShopsLimit:
                return "Bạn đã đạt giới hạn tối đa \(Shop.maxShopsPerUser) cửa hàng"
            case .invalidShopName:
                return "Tên cửa hàng không hợp lệ"
            case .invalidGroundRent:
                return "Chi phí mặt bằng không hợp lệ"
            case .invalidAddress:
                return "Địa chỉ không hợp lệ"
            case .invalidBusinessHours:
                return "Giờ hoạt động không hợp lệ"
            case .invalidPointRate:
                return "Tỷ lệ tích điểm không hợp lệ"
            }
        }
    }
    
    static func validate(shopName: String, groundRent: Double, ownerId: String, existingShops: [Shop]) throws {
        // Validate shop name
        let trimmedName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidShopName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
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
    
    func validate() throws {
        // Validate shop name
        let trimmedName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidShopName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidShopName
        }
        
        // Validate ground rent
        guard groundRent >= 0 else {
            throw ValidationError.invalidGroundRent
        }
        
        // Validate address
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            throw ValidationError.invalidAddress
        }
        
        guard trimmedAddress.count >= 5 && trimmedAddress.count <= 200 else {
            throw ValidationError.invalidAddress
        }
        
        // Validate business hours
        let openTimeInMinutes = businessHours.openHour * 60 + businessHours.openMinute
        let closeTimeInMinutes = businessHours.closeHour * 60 + businessHours.closeMinute
        
        if closeTimeInMinutes > openTimeInMinutes {
            guard closeTimeInMinutes - openTimeInMinutes >= 60 else { // At least 1 hour
                throw ValidationError.invalidBusinessHours
            }
        } else {
            // Handle overnight hours
            let totalMinutes = (24 * 60 - openTimeInMinutes) + closeTimeInMinutes
            guard totalMinutes >= 60 else {
                throw ValidationError.invalidBusinessHours
            }
        }
        
        // Validate point rate
        guard pointRate >= 0 && pointRate <= 100 else {
            throw ValidationError.invalidPointRate
        }
    }
}
