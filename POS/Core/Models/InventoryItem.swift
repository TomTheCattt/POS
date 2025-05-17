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
    let id: String
    let name: String
    let category: InventoryCategory
    var quantity: Double
    let unit: String
    let unitPrice: Double
    let minimumQuantity: Double
    let supplier: String?
    let location: String?
    let notes: String?
    let lastRestockDate: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    var value: Double {
        quantity * unitPrice
    }
    
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
        category: InventoryCategory,
        quantity: Double,
        unit: String,
        unitPrice: Double,
        minimumQuantity: Double,
        supplier: String? = nil,
        location: String? = nil,
        notes: String? = nil,
        lastRestockDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.minimumQuantity = minimumQuantity
        self.supplier = supplier
        self.location = location
        self.notes = notes
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
            let categoryRaw = data["category"] as? String,
            let category = InventoryCategory(rawValue: categoryRaw),
            let quantity = data["quantity"] as? Double,
            let unit = data["unit"] as? String,
            let unitPrice = data["unitPrice"] as? Double,
            let minimumQuantity = data["minimumQuantity"] as? Double,
            let createdAt = data["createdAt"] as? Timestamp,
            let updatedAt = data["updatedAt"] as? Timestamp
        else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.minimumQuantity = minimumQuantity
        self.supplier = data["supplier"] as? String
        self.location = data["location"] as? String
        self.notes = data["notes"] as? String
        self.lastRestockDate = (data["lastRestockDate"] as? Timestamp)?.dateValue()
        self.createdAt = createdAt.dateValue()
        self.updatedAt = updatedAt.dateValue()
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "category": category.rawValue,
            "quantity": quantity,
            "unit": unit,
            "unitPrice": unitPrice,
            "minimumQuantity": minimumQuantity,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let supplier = supplier {
            dict["supplier"] = supplier
        }
        
        if let location = location {
            dict["location"] = location
        }
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        if let lastRestockDate = lastRestockDate {
            dict["lastRestockDate"] = Timestamp(date: lastRestockDate)
        }
        
        return dict
    }
}
