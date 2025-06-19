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
    
    var availabilityStatus: String {
        if isAvailable {
            return "Có sẵn"
        } else {
            return "Hết hàng"
        }
    }
    
    var availabilityColor: String {
        return isAvailable ? "green" : "red"
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
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "menuId": menuId,
            "name": name,
            "price": price,
            "category": category,
            "isAvailable": isAvailable,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        // Handle recipe array - store as array of dictionaries for Firestore nested array support
        if !recipe.isEmpty {
            dict["recipe"] = recipe.map { $0.dictionary }
        }
        
        if let imageURL = imageURL {
            dict["imageURL"] = imageURL.absoluteString
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let menuId = dictionary["menuId"] as? String,
              let name = dictionary["name"] as? String,
              let price = dictionary["price"] as? Double,
              let category = dictionary["category"] as? String,
              let isAvailable = dictionary["isAvailable"] as? Bool,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        // Parse recipe array
        var recipe: [Recipe] = []
        if let recipeArray = dictionary["recipe"] as? [[String: Any]] {
            recipe = recipeArray.compactMap { recipeDict in
                guard let ingredientId = recipeDict["ingredientId"] as? String,
                      let ingredientName = recipeDict["ingredientName"] as? String,
                      let requiredAmountDict = recipeDict["requiredAmount"] as? [String: Any],
                      let requiredAmountValue = requiredAmountDict["value"] as? Double,
                      let requiredAmountUnitRaw = requiredAmountDict["unit"] as? String,
                      let requiredAmountUnit = MeasurementUnit(rawValue: requiredAmountUnitRaw),
                      let createdAtTimestamp = recipeDict["createdAt"] as? Timestamp,
                      let updatedAtTimestamp = recipeDict["updatedAt"] as? Timestamp else {
                    return nil
                }
                
                return Recipe(
                    ingredientId: ingredientId,
                    ingredientName: ingredientName,
                    requiredAmount: Measurement(value: requiredAmountValue, unit: requiredAmountUnit),
                    createdAt: createdAtTimestamp.dateValue(),
                    updatedAt: updatedAtTimestamp.dateValue()
                )
            }
        }
        
        // Parse imageURL
        var imageURL: URL?
        if let imageURLString = dictionary["imageURL"] as? String {
            imageURL = URL(string: imageURLString)
        }
        
        self.init(
            menuId: menuId,
            name: name,
            price: price,
            category: category,
            recipe: recipe,
            isAvailable: isAvailable,
            imageURL: imageURL,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
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
    
    mutating func clearRecipe() {
        recipe.removeAll()
        updatedAt = Date()
    }
    
    // MARK: - Mutating Methods
    mutating func updateName(_ newName: String) {
        name = newName
        updatedAt = Date()
    }
    
    mutating func updatePrice(_ newPrice: Double) {
        price = newPrice
        updatedAt = Date()
    }
    
    mutating func updateCategory(_ newCategory: String) {
        category = newCategory
        updatedAt = Date()
    }
    
    mutating func updateImageURL(_ newImageURL: URL?) {
        imageURL = newImageURL
        updatedAt = Date()
    }
    
    mutating func setAvailable(_ available: Bool) {
        isAvailable = available
        updatedAt = Date()
    }
    
    // MARK: - Helper Methods
    func canBeMadeWith(ingredients: [String: IngredientUsage]) -> Bool {
        guard hasRecipe else { return true }
        
        return recipe.allSatisfy { recipeItem in
            guard let ingredient = ingredients[recipeItem.ingredientId] else {
                return false
            }
            
            return recipeItem.canBeMadeWith(ingredient: ingredient)
        }
    }
    
    func getMissingIngredients(ingredients: [String: IngredientUsage]) -> [String] {
        guard hasRecipe else { return [] }
        
        return recipe.compactMap { recipeItem in
            guard let ingredient = ingredients[recipeItem.ingredientId] else {
                return recipeItem.ingredientName
            }
            
            if !recipeItem.canBeMadeWith(ingredient: ingredient) {
                return recipeItem.ingredientName
            }
            
            return nil
        }
    }
    
    func getRequiredIngredients() -> [String] {
        return recipe.map { $0.ingredientName }
    }
    
    func getTotalCost(ingredients: [String: IngredientUsage]) -> Double {
        return recipe.reduce(0) { total, recipeItem in
            guard let ingredient = ingredients[recipeItem.ingredientId] else {
                return total
            }
            
            let requiredAmount = recipeItem.requiredAmount.value
            let costPerUnit = ingredient.costPrice
            return total + (requiredAmount * costPerUnit)
        }
    }
    
    func getProfitMargin(ingredients: [String: IngredientUsage]) -> Double {
        let totalCost = getTotalCost(ingredients: ingredients)
        guard totalCost > 0 else { return 0 }
        
        return ((price - totalCost) / price) * 100
    }
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

// MARK: - Validation
extension MenuItem {
    enum ValidationError: LocalizedError {
        case invalidName
        case invalidPrice
        case invalidCategory
        case invalidPreparationTime
        case invalidDescription
        case duplicateName
        
        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "Tên món không hợp lệ"
            case .invalidPrice:
                return "Giá món không hợp lệ"
            case .invalidCategory:
                return "Danh mục không hợp lệ"
            case .invalidPreparationTime:
                return "Thời gian chuẩn bị không hợp lệ"
            case .invalidDescription:
                return "Mô tả không hợp lệ"
            case .duplicateName:
                return "Tên món đã tồn tại"
            }
        }
    }
    
    func validate() throws {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidName
        }
        
        // Validate price
        guard price > 0 else {
            throw ValidationError.invalidPrice
        }
        
        guard price <= 10000000 else { // Max 10 million VND
            throw ValidationError.invalidPrice
        }
        
        // Validate category
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else {
            throw ValidationError.invalidCategory
        }
        
        guard trimmedCategory.count >= 2 && trimmedCategory.count <= 50 else {
            throw ValidationError.invalidCategory
        }
    }
    
    static func validateName(_ name: String, existingItems: [MenuItem], excludeId: String? = nil) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidName
        }
        
        // Check for duplicate names
        let duplicateExists = existingItems.contains { item in
            item.name.lowercased() == trimmedName.lowercased() && item.id != excludeId
        }
        
        if duplicateExists {
            throw ValidationError.duplicateName
        }
    }
}


