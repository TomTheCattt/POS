//
//  MenuItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

struct MenuItem: Codable, Identifiable {
    // MARK: - Properties
    @DocumentID var id: String?
    let name: String
    let price: Double
    let category: String
    var ingredients: [IngredientUsage]
    private(set) var isAvailable: Bool
    var imageURL: URL?
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        name: String,
        price: Double,
        category: String,
        ingredients: [IngredientUsage] = [],
        isAvailable: Bool = true,
        imageURL: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.category = category
        self.ingredients = ingredients
        self.isAvailable = isAvailable
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Availability Methods
    mutating func updateAvailability(with inventoryItems: [String: InventoryItem]) {
        // Nếu không có nguyên liệu, món luôn available
        guard !ingredients.isEmpty else {
            isAvailable = true
            return
        }
        
        // Kiểm tra từng nguyên liệu
        isAvailable = ingredients.allSatisfy { ingredient in
            guard let inventoryItem = inventoryItems[ingredient.inventoryItemID] else {
                return false // Nếu không tìm thấy nguyên liệu trong kho, món không available
            }
            
            // Kiểm tra đơn vị đo
            if ingredient.unit != inventoryItem.unit {
                // Cần chuyển đổi đơn vị nếu khác nhau
                let convertedQuantity = convertQuantity(
                    ingredient.quantity,
                    from: ingredient.unit,
                    to: inventoryItem.unit
                )
                return inventoryItem.quantity >= convertedQuantity
            }
            
            // Nếu cùng đơn vị, so sánh trực tiếp
            return inventoryItem.quantity >= ingredient.quantity
        }
    }
    
    private func convertQuantity(_ quantity: Double, from sourceUnit: MeasurementUnit, to targetUnit: MeasurementUnit) -> Double {
        // Chuyển đổi giữa các đơn vị
        switch (sourceUnit, targetUnit) {
        case (.gram, .kilogram):
            return quantity / 1000
        case (.kilogram, .gram):
            return quantity * 1000
        case (.milliliter, .liter):
            return quantity / 1000
        case (.liter, .milliliter):
            return quantity * 1000
        default:
            return quantity // Trường hợp cùng đơn vị hoặc không thể chuyển đổi
        }
    }
    
    // MARK: - Dictionary Representation
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "price": price,
            "category": category,
            "ingredients": ingredients.map { $0.dictionary },
            "isAvailable": isAvailable,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let imageURL = imageURL {
            dict["imageURL"] = imageURL.absoluteString
        }
        
        return dict
    }
}

struct IngredientUsage: Codable, Identifiable {
    var id: String { inventoryItemID }
    let inventoryItemID: String
    let quantity: Double
    let unit: MeasurementUnit
    
    init(inventoryItemID: String, quantity: Double, unit: MeasurementUnit) {
        self.inventoryItemID = inventoryItemID
        self.quantity = quantity
        self.unit = unit
    }
    
    var dictionary: [String: Any] {
        [
            "inventoryItemID": inventoryItemID,
            "quantity": quantity,
            "unit": unit.rawValue
        ]
    }
}

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case gram = "g"
    case kilogram = "kg"
    case milliliter = "ml"
    case liter = "l"
    case piece = "cái"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gram:
            return "Gram"
        case .kilogram:
            return "Kilogram"
        case .milliliter:
            return "Mililít"
        case .liter:
            return "Lít"
        case .piece:
            return "Miếng"
        }
    }
}

// MARK: - Firestore Extensions
extension MenuItem {
    init?(document: DocumentSnapshot) {
        guard
            let data = document.data(),
            let name = data["name"] as? String,
            let price = data["price"] as? Double,
            let category = data["category"] as? String,
            let isAvailable = data["isAvailable"] as? Bool,
            let ingredientsData = data["ingredients"] as? [[String: Any]]
        else {
            return nil
        }
        
        let ingredients = ingredientsData.compactMap { dict -> IngredientUsage? in
            guard
                let inventoryItemID = dict["inventoryItemID"] as? String,
                let quantity = dict["quantity"] as? Double,
                let unitString = dict["unit"] as? String,
                let unit = MeasurementUnit(rawValue: unitString)
            else {
                return nil
            }
            return IngredientUsage(inventoryItemID: inventoryItemID, quantity: quantity, unit: unit)
        }
        
        if let imageURLString = data["imageURL"] as? String {
            self.imageURL = URL(string: imageURLString)
        } else {
            self.imageURL = nil
        }
        
        self.id = document.documentID
        self.name = name
        self.price = price
        self.category = category
        self.ingredients = ingredients
        self.isAvailable = isAvailable
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}

