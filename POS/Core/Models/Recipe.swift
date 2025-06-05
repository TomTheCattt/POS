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
    @DocumentID var id: String?
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
            name: ingredientName,
            quantity: 0,
            measurementPerUnit: Measurement(value: 1, unit: requiredAmount.unit),
            used: 0,
            costPrice: 0,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    init(
        id: String? = nil,
        ingredientId: String,
        ingredientName: String,
        requiredAmount: Measurement,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ingredientId = ingredientId
        self.ingredientName = ingredientName
        self.requiredAmount = requiredAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

    var dictionary: [String: Any] {
        [
            "ingredientId": ingredientId,
            "ingredientName": ingredientName,
            "requiredAmount": requiredAmount.dictionary,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let ingredientId = dictionary["ingredientId"] as? String,
              let ingredientName = dictionary["ingredientName"] as? String,
              let requiredAmountDict = dictionary["requiredAmount"] as? [String: Any],
              let requiredAmount = Measurement(dictionary: requiredAmountDict),
              let createdAt = (dictionary["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (dictionary["updatedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.init(
            ingredientId: ingredientId,
            ingredientName: ingredientName,
            requiredAmount: requiredAmount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
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

extension Recipe {
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        // Try new format first
        if let ingredientId = data["ingredientId"] as? String,
           let ingredientName = data["ingredientName"] as? String,
           let requiredAmountDict = data["requiredAmount"] as? [String: Any],
           let requiredAmount = Measurement(dictionary: requiredAmountDict),
           let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
           let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() {
            
            self.init(
                id: document.documentID,
                ingredientId: ingredientId,
                ingredientName: ingredientName,
                requiredAmount: requiredAmount,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            return
        }
        
        // Fallback for old format
        guard let ingredientDict = data["ingredientUsage"] as? [String: Any],
              let measurementDict = data["measurement"] as? [String: Any],
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue(),
              let ingredientUsage = IngredientUsage(dictionary: ingredientDict),
              let measurement = Measurement(dictionary: measurementDict)
        else {
            return nil
        }

        self.init(
            id: document.documentID,
            ingredientUsage: ingredientUsage,
            measurement: measurement,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
