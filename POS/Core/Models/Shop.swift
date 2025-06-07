//
//  Shop.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation
import FirebaseFirestore

struct Shop: Codable, Identifiable {
    // MARK: - Constants
    static let maxShopsPerUser = 4
    
    // MARK: - Properties
    @DocumentID var id: String?
    let shopName: String
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    let ownerId: String // Thêm trường để liên kết với user
    
    // MARK: - Dictionary Representation
    var dictionary: [String: Any] {
        [
            "shopName": shopName,
            "isActive": isActive,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "ownerId": ownerId
        ]
    }
}

// MARK: - Validation
extension Shop {
    enum ValidationError: LocalizedError {
        case exceedMaxShopsLimit
        case invalidShopName
        
        var errorDescription: String? {
            switch self {
            case .exceedMaxShopsLimit:
                return "Bạn đã đạt giới hạn tối đa \(Shop.maxShopsPerUser) cửa hàng"
            case .invalidShopName:
                return "Tên cửa hàng không hợp lệ"
            }
        }
    }
    
    static func validate(shopName: String, ownerId: String, existingShops: [Shop]) throws {
        // Validate shop name
        guard !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidShopName
        }
        
        // Validate max shops limit
        let userShops = existingShops.filter { $0.ownerId == ownerId }
        guard userShops.count < maxShopsPerUser else {
            throw ValidationError.exceedMaxShopsLimit
        }
    }
}

