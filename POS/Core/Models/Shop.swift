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

struct Shop: Codable, Identifiable {
    // MARK: - Constants
    static let maxShopsPerUser = 4
    
    // MARK: - Properties
    @DocumentID var id: String?
    let shopName: String
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    let ownerId: String
    var groundRent: Double
    var currency: Currency
    var address: String
    
    // MARK: - Computed Properties
    var formattedGroundRent: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: groundRent)) ?? "0"
        return "\(formattedNumber)\(currency.symbol)/tháng"
    }
    
    // MARK: - Dictionary Representation
    var dictionary: [String: Any] {
        [
            "shopName": shopName,
            "isActive": isActive,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "ownerId": ownerId,
            "groundRent": groundRent,
            "currency": currency.rawValue,
            "address": address
        ]
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

