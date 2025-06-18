//
//  Recipe.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Recipe Structure
struct Recipe: Codable, Identifiable, Hashable {
    var id: String?
    let ingredientId: String
    let ingredientName: String
    var requiredAmount: Measurement
    let createdAt: Date
    var updatedAt: Date
    
    // For backward compatibility, keep ingredientUsage as computed property
    var ingredientUsage: IngredientUsage {
        // This should be populated from external source when needed
        // For now, return a placeholder - this design should be reconsidered
        return IngredientUsage(
            shopId: "",
            name: ingredientName,
            quantity: 0,
            measurementPerUnit: Measurement(value: 1, unit: requiredAmount.unit),
            used: 0,
            minQuantity: 1,
            costPrice: 0,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    init(
        id: String? = nil,
        ingredientUsage: IngredientUsage,
        measurement: Measurement,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ingredientId = ingredientUsage.id ?? ""
        self.ingredientName = ingredientUsage.name
        self.requiredAmount = measurement
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(ingredientName)
    }
    
    // MARK: - Helper Methods
    func canBeMadeWith(ingredient: IngredientUsage) -> Bool {
        guard ingredient.name == ingredientName else { return false }
        
        let availableAmount = ingredient.availableMeasurement
        guard let requiredInAvailableUnit = requiredAmount.converted(to: availableAmount.unit) else {
            return false
        }
        
        return availableAmount.isGreaterThan(requiredInAvailableUnit) ||
               availableAmount.value >= requiredInAvailableUnit.value
    }
}
