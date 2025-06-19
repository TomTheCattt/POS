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
    
    // MARK: - Initialization
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
    
    // MARK: - Computed Properties
    var displayName: String {
        return ingredientName
    }
    
    var formattedRequiredAmount: String {
        return requiredAmount.displayString
    }
    
    var icon: String {
        return "leaf"
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        [
            "ingredientId": ingredientId,
            "ingredientName": ingredientName,
            "requiredAmount": [
                "value": requiredAmount.value,
                "unit": requiredAmount.unit.rawValue
            ],
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let ingredientId = dictionary["ingredientId"] as? String,
              let ingredientName = dictionary["ingredientName"] as? String,
              let requiredAmountDict = dictionary["requiredAmount"] as? [String: Any],
              let requiredAmountValue = requiredAmountDict["value"] as? Double,
              let requiredAmountUnitRaw = requiredAmountDict["unit"] as? String,
              let requiredAmountUnit = MeasurementUnit(rawValue: requiredAmountUnitRaw),
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        let requiredAmount = Measurement(value: requiredAmountValue, unit: requiredAmountUnit)
        
        self.init(
            ingredientId: ingredientId,
            ingredientName: ingredientName,
            requiredAmount: requiredAmount,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(ingredientName)
        hasher.combine(ingredientId)
    }
    
    // MARK: - Mutating Methods
    mutating func updateRequiredAmount(_ newAmount: Measurement) {
        requiredAmount = newAmount
        updatedAt = Date()
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
    
    func getMissingAmount(ingredient: IngredientUsage) -> Measurement? {
        guard ingredient.name == ingredientName else { return nil }
        
        let availableAmount = ingredient.availableMeasurement
        guard let requiredInAvailableUnit = requiredAmount.converted(to: availableAmount.unit) else {
            return nil
        }
        
        if availableAmount.value >= requiredInAvailableUnit.value {
            return nil // No missing amount
        }
        
        let missingValue = requiredInAvailableUnit.value - availableAmount.value
        return Measurement(value: missingValue, unit: availableAmount.unit)
    }
    
    func getCost(ingredient: IngredientUsage) -> Double {
        guard ingredient.name == ingredientName else { return 0 }
        
        let costPerUnit = ingredient.costPrice
        let requiredQuantity = requiredAmount.value
        
        return costPerUnit * requiredQuantity
    }
    
    func getFormattedCost(ingredient: IngredientUsage) -> String {
        let cost = getCost(ingredient: ingredient)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: cost)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    func isIngredientSufficient(ingredient: IngredientUsage) -> Bool {
        return canBeMadeWith(ingredient: ingredient)
    }
    
    func getIngredientStatus(ingredient: IngredientUsage) -> IngredientStatus {
        if canBeMadeWith(ingredient: ingredient) {
            return .sufficient
        } else if let missingAmount = getMissingAmount(ingredient: ingredient) {
            return .insufficient(missingAmount: missingAmount)
        } else {
            return .unavailable
        }
    }
}

// MARK: - Ingredient Status
enum IngredientStatus {
    case sufficient
    case insufficient(missingAmount: Measurement)
    case unavailable
    
    var description: String {
        switch self {
        case .sufficient:
            return "Đủ nguyên liệu"
        case .insufficient(let missingAmount):
            return "Thiếu \(missingAmount.displayString)"
        case .unavailable:
            return "Không có nguyên liệu"
        }
    }
    
    var color: Color {
        switch self {
        case .sufficient:
            return .green
        case .insufficient:
            return .orange
        case .unavailable:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .sufficient:
            return "checkmark.circle.fill"
        case .insufficient:
            return "exclamationmark.triangle.fill"
        case .unavailable:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Validation
extension Recipe {
    enum ValidationError: LocalizedError {
        case invalidIngredientId
        case invalidIngredientName
        case invalidRequiredAmount
        case invalidNotes
        case invalidPreparationTime
        case invalidCookingMethod
        
        var errorDescription: String? {
            switch self {
            case .invalidIngredientId:
                return "ID nguyên liệu không hợp lệ"
            case .invalidIngredientName:
                return "Tên nguyên liệu không hợp lệ"
            case .invalidRequiredAmount:
                return "Số lượng yêu cầu không hợp lệ"
            case .invalidNotes:
                return "Ghi chú không hợp lệ"
            case .invalidPreparationTime:
                return "Thời gian chuẩn bị không hợp lệ"
            case .invalidCookingMethod:
                return "Phương pháp nấu không hợp lệ"
            }
        }
    }
    
    func validate() throws {
        // Validate ingredient ID
        guard !ingredientId.isEmpty else {
            throw ValidationError.invalidIngredientId
        }
        
        // Validate ingredient name
        let trimmedName = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidIngredientName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidIngredientName
        }
        
        // Validate required amount
        try requiredAmount.validate()
    }
    
    static func validateIngredientName(_ name: String, existingRecipes: [Recipe], excludeId: String? = nil) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidIngredientName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidIngredientName
        }
        
        // Check for duplicate ingredient names in the same recipe
        let duplicateExists = existingRecipes.contains { recipe in
            recipe.ingredientName.lowercased() == trimmedName.lowercased() && recipe.id != excludeId
        }
        
        if duplicateExists {
            throw ValidationError.invalidIngredientName
        }
    }
}

// MARK: - Recipe Factory Methods
extension Recipe {
    static func createRecipe(
        ingredientId: String,
        ingredientName: String,
        requiredAmount: Measurement
    ) -> Recipe {
        return Recipe(
            ingredientId: ingredientId,
            ingredientName: ingredientName,
            requiredAmount: requiredAmount
        )
    }
    
    static func createRecipeFromIngredient(
        ingredient: IngredientUsage,
        requiredAmount: Measurement
    ) -> Recipe {
        return Recipe(
            ingredientId: ingredient.id ?? "",
            ingredientName: ingredient.name,
            requiredAmount: requiredAmount
        )
    }
}
