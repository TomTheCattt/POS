//
//  MenuItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

struct MenuItem: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let price: Double
    let category: String
    var ingredients: [IngredientUsage]?
    var isAvailable: Bool?
    var imageURL: URL?
    let createdAt: Date
    var updatedAt: Date
    
    var dictionary: [String: Any] {
        [
            "name": name,
            "price": price,
            "category": category,
            "imageURL": imageURL?.absoluteString as Any,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

struct IngredientUsage: Codable {
    let inventoryItemID: String
    let quantity: Double
    let unit: String
    
    var dictionary: [String: Any] {
        [
            "inventoryItemID": inventoryItemID,
            "quantity": quantity,
            "unit": unit
        ]
    }
}

enum MeasurementUnit: String, Codable, CaseIterable, Hashable {
    case gram
    case kilogram
    case milliliter
    case liter
    case piece
}

extension MenuItem {
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["name"] as? String,
              let price = data["price"] as? Double,
              let category = data["category"] as? String,
              let isAvailable = data["isAvailable"] as? Bool,
              let ingredientsData = data["ingredients"] as? [[String: Any]]
        else {
            return nil
        }

        let ingredients: [IngredientUsage] = ingredientsData.compactMap { dict in
            guard let inventoryItemID = dict["inventoryItemID"] as? String,
                  let quantity = dict["quantity"] as? Double,
                  let unitRaw = dict["unit"] as? String,
                  let unit = MeasurementUnit(rawValue: unitRaw) else {
                return IngredientUsage(inventoryItemID: "Error", quantity: 0, unit: "Error")
            }
            return IngredientUsage(inventoryItemID: inventoryItemID, quantity: quantity, unit: unit.rawValue)
        }

        self.id = document.documentID
        self.name = name
        self.price = price
        self.category = category
        self.ingredients = ingredients
        self.isAvailable = isAvailable

        if let imageURLString = data["imageURL"] as? String, let url = URL(string: imageURLString) {
            self.imageURL = url
        } else {
            self.imageURL = nil
        }

        if let createdAt = data["createdAt"] as? Timestamp {
            self.createdAt = createdAt.dateValue()
        } else {
            self.createdAt = Date()
        }

        if let updatedAt = data["updatedAt"] as? Timestamp {
            self.updatedAt = updatedAt.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
}

