//
//  InventoryItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct InventoryItem: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    var quantity: Double
    let unit: String
    let minimumQuantity: Double
    let lastRestockDate: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    
    var isLowStock: Bool {
        quantity <= minimumQuantity
    }
    
    var stockStatus: StockStatus {
        if quantity <= 0 {
            return .outOfStock
        } else if isLowStock {
            return .lowStock
        } else {
            return .inStock
        }
    }
    
    // MARK: - Initialization
    init(
        id: String,
        name: String,
        quantity: Double,
        unit: String,
        minimumQuantity: Double,
        lastRestockDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.minimumQuantity = minimumQuantity
        self.lastRestockDate = lastRestockDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supporting Types
extension InventoryItem {
    enum StockStatus {
        case inStock
        case lowStock
        case outOfStock
        
        var description: String {
            switch self {
            case .inStock:
                return "Còn hàng"
            case .lowStock:
                return "Sắp hết hàng"
            case .outOfStock:
                return "Hết hàng"
            }
        }
        
        var color: Color {
            switch self {
            case .inStock:
                return .green
            case .lowStock:
                return .orange
            case .outOfStock:
                return .red
            }
        }
    }
}

// MARK: - Equatable
extension InventoryItem: Equatable {
    static func == (lhs: InventoryItem, rhs: InventoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension InventoryItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Firebase Helpers
extension InventoryItem {
    init?(document: DocumentSnapshot) {
        guard 
            let data = document.data(),
            let name = data["name"] as? String,
            let quantity = data["quantity"] as? Double,
            let unit = data["unit"] as? String,
            let minimumQuantity = data["minimumQuantity"] as? Double,
            let createdAt = data["createdAt"] as? Timestamp,
            let updatedAt = data["updatedAt"] as? Timestamp
        else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.minimumQuantity = minimumQuantity
        self.lastRestockDate = (data["lastRestockDate"] as? Timestamp)?.dateValue()
        self.createdAt = createdAt.dateValue()
        self.updatedAt = updatedAt.dateValue()
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "quantity": quantity,
            "unit": unit,
            "minimumQuantity": minimumQuantity,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        
        if let lastRestockDate = lastRestockDate {
            dict["lastRestockDate"] = lastRestockDate
        }
        
        return dict
    }
}
