//
//  MenuItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

struct MenuItem: Codable, Identifiable {
    // MARK: - Properties
    @DocumentID var id: String?
    let menuId: String
    var name: String
    var price: Double
    var category: String
    var recipe: [Recipe]
    private(set) var isAvailable: Bool
    var imageURL: URL?
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    var formattedPrice: String {
        return String(format: "%.0f VNĐ", price)
    }
    
    var hasRecipe: Bool {
        return !recipe.isEmpty
    }
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        menuId: String,
        name: String,
        price: Double,
        category: String,
        recipe: [Recipe] = [],
        isAvailable: Bool = true,
        imageURL: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.menuId = menuId
        self.name = name
        self.price = price
        self.category = category
        self.recipe = recipe
        self.isAvailable = isAvailable
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Availability Management
    mutating func updateAvailability(ingredients: [String: IngredientUsage]) {
        guard hasRecipe else {
            isAvailable = true
            updatedAt = Date()
            return
        }
        
        let wasAvailable = isAvailable
        isAvailable = checkAvailability(with: ingredients)
        
        // Only update timestamp if availability changed
        if wasAvailable != isAvailable {
            updatedAt = Date()
        }
    }
    
    private func checkAvailability(with ingredients: [String: IngredientUsage]) -> Bool {
        return recipe.allSatisfy { recipeItem in
            guard let ingredient = ingredients[recipeItem.ingredientId] else {
                return false
            }
            
            let requiredQuantity = convertToBaseUnit(
                quantity: ingredient.quantity,
                unit: ingredient.measurementPerUnit.unit
            )
            
            let availableQuantity = convertToBaseUnit(
                quantity: ingredient.totalMeasurement - ingredient.used,
                unit: ingredient.measurementPerUnit.unit
            )
            
            return availableQuantity >= requiredQuantity
        }
    }
    
    // MARK: - Unit Conversion
    private func convertToBaseUnit(quantity: Double, unit: MeasurementUnit) -> Double {
        switch unit {
        case .gram, .milliliter:
            return quantity
        case .kilogram:
            return quantity * 1000
        case .liter:
            return quantity * 1000
        case .piece:
            return quantity
        }
    }
    
    private func convertQuantity(
        _ quantity: Double,
        from sourceUnit: MeasurementUnit,
        to targetUnit: MeasurementUnit
    ) -> Double? {
        if sourceUnit == targetUnit { return quantity }
        
        // Convert both to base units first, then to target
        let baseQuantity = convertToBaseUnit(quantity: quantity, unit: sourceUnit)
        
        switch targetUnit {
        case .gram, .milliliter:
            return baseQuantity
        case .kilogram, .liter:
            return baseQuantity / 1000
        case .piece:
            return baseQuantity // Direct conversion for discrete units
        }
    }
    
    // MARK: - Recipe Management
    mutating func addRecipeItem(_ recipeItem: Recipe) {
        recipe.append(recipeItem)
        updatedAt = Date()
    }
    
    mutating func removeRecipeItem(at index: Int) {
        guard index >= 0 && index < recipe.count else { return }
        recipe.remove(at: index)
        updatedAt = Date()
    }
    
    mutating func updateRecipeItem(at index: Int, with newRecipeItem: Recipe) {
        guard index >= 0 && index < recipe.count else { return }
        recipe[index] = newRecipeItem
        updatedAt = Date()
    }
    
    // MARK: - Dictionary Representation
//    var dictionary: [String: Any] {
//        var dict: [String: Any] = [
//            "name": name,
//            "price": price,
//            "category": category,
//            "recipe": recipe.map { $0.dictionary },
//            "isAvailable": isAvailable,
//            "createdAt": Timestamp(date: createdAt),
//            "updatedAt": Timestamp(date: updatedAt)
//        ]
//        
//        if let imageURL = imageURL {
//            dict["imageURL"] = imageURL.absoluteString
//        }
//        
//        return dict
//    }
}

// MARK: - Comparable
extension MenuItem: Comparable {
    static func < (lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.name < rhs.name
    }
}

// MARK: - Hashable
extension MenuItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(price)
        hasher.combine(category)
    }
}


