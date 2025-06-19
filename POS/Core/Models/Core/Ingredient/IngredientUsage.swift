//
//  IngredientUsage.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 2/6/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

struct IngredientUsage: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let shopId: String
    let name: String
    var quantity: Double
    var measurementPerUnit: Measurement
    var used: Double
    var minQuantity: Double
    var costPrice: Double
    let createdAt: Date
    var updatedAt: Date
    var expiryDate: Date?

    // MARK: - Initialization
    init(
        id: String? = nil,
        shopId: String,
        name: String,
        quantity: Double,
        measurementPerUnit: Measurement,
        used: Double = 0.0,
        minQuantity: Double = 0.0,
        costPrice: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        expiryDate: Date? = nil
    ) {
        self.id = id
        self.shopId = shopId
        self.name = name
        self.quantity = quantity
        self.measurementPerUnit = measurementPerUnit
        self.used = used
        self.minQuantity = minQuantity
        self.costPrice = costPrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expiryDate = expiryDate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Computed Properties

    var totalMeasurement: Double {
        quantity * measurementPerUnit.value
    }

    var isLowStock: Bool {
        totalMeasurement - used <= minQuantity * measurementPerUnit.value
    }

    var stockStatus: StockStatus {
        if quantity <= 0.0 {
            return .outOfStock
        } else if isLowStock {
            return .lowStock
        } else {
            return .inStock
        }
    }
    
    var formattedQuantity: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let formattedNumber = formatter.string(from: NSNumber(value: quantity)) ?? "0"
        return "\(formattedNumber) \(measurementPerUnit.unit.shortDisplayName)"
    }
    
    var formattedCostPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: costPrice)) ?? "0"
        return "\(formattedNumber)đ/\(measurementPerUnit.unit.shortDisplayName)"
    }
    
    var formattedTotalCost: String {
        let totalCost = quantity * costPrice
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: totalCost)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    var formattedExpiryDate: String {
        guard let expiryDate = expiryDate else { return "Không có hạn sử dụng" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: expiryDate)
    }
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return Date() > expiryDate
    }
    
    var isExpiringSoon: Bool {
        guard let expiryDate = expiryDate else { return false }
        let calendar = Calendar.current
        let daysUntilExpiry = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return daysUntilExpiry <= 7 && daysUntilExpiry > 0
    }
    
    var stockPercentage: Double {
        guard totalMeasurement > 0 else { return 0 }
        let available = totalMeasurement - used
        return min(100, (available / totalMeasurement) * 100)
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "shopId": shopId,
            "name": name,
            "quantity": quantity,
            "measurementPerUnit": [
                "value": measurementPerUnit.value,
                "unit": measurementPerUnit.unit.rawValue
            ],
            "used": used,
            "minQuantity": minQuantity,
            "costPrice": costPrice,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let expiryDate = expiryDate {
            dict["expiryDate"] = Timestamp(date: expiryDate)
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let shopId = dictionary["shopId"] as? String,
              let name = dictionary["name"] as? String,
              let quantity = dictionary["quantity"] as? Double,
              let measurementPerUnitDict = dictionary["measurementPerUnit"] as? [String: Any],
              let measurementValue = measurementPerUnitDict["value"] as? Double,
              let measurementUnitRaw = measurementPerUnitDict["unit"] as? String,
              let measurementUnit = MeasurementUnit(rawValue: measurementUnitRaw),
              let used = dictionary["used"] as? Double,
              let minQuantity = dictionary["minQuantity"] as? Double,
              let costPrice = dictionary["costPrice"] as? Double,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        let measurementPerUnit = Measurement(value: measurementValue, unit: measurementUnit)
        
        // Parse optional fields
        var expiryDate: Date?
        if let expiryDateTimestamp = dictionary["expiryDate"] as? Timestamp {
            expiryDate = expiryDateTimestamp.dateValue()
        }
        
        self.init(
            shopId: shopId,
            name: name,
            quantity: quantity,
            measurementPerUnit: measurementPerUnit,
            used: used,
            minQuantity: minQuantity,
            costPrice: costPrice,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            expiryDate: expiryDate
        )
    }
}

// MARK: - Stock Status Enum

extension IngredientUsage {
    enum StockStatus: String, Codable, CaseIterable {
        case inStock = "inStock"
        case lowStock = "lowStock"
        case outOfStock = "outOfStock"

        var description: String {
            switch self {
            case .inStock: return "Còn hàng"
            case .lowStock: return "Sắp hết hàng"
            case .outOfStock: return "Hết hàng"
            }
        }

        var color: Color {
            switch self {
            case .inStock: return .green
            case .lowStock: return .orange
            case .outOfStock: return .red
            }
        }
        
        var systemImage: String {
            switch self {
            case .inStock: return "checkmark.circle.fill"
            case .lowStock: return "exclamationmark.triangle.fill"
            case .outOfStock: return "xmark.circle.fill"
            }
        }
        
        var icon: String {
            switch self {
            case .inStock: return "checkmark.circle"
            case .lowStock: return "exclamationmark.triangle"
            case .outOfStock: return "xmark.circle"
            }
        }
    }
    
    // MARK: - Enhanced Computed Properties
    var availableMeasurement: Measurement {
        let availableQuantity = max(0, quantity - (used / measurementPerUnit.value))
        return Measurement(value: availableQuantity, unit: measurementPerUnit.unit)
    }
    
    var usedMeasurement: Measurement {
        let usedQuantity = used / measurementPerUnit.value
        return Measurement(value: usedQuantity, unit: measurementPerUnit.unit)
    }
    
    var totalMeasurementObject: Measurement {
        return Measurement(value: quantity, unit: measurementPerUnit.unit)
    }
    
    var minQuantityMeasurement: Measurement {
        return Measurement(value: minQuantity, unit: measurementPerUnit.unit)
    }
    
    // MARK: - Stock Management
    mutating func consume(amount: Measurement) -> Bool {
        guard let amountInBaseUnit = amount.converted(to: measurementPerUnit.unit) else {
            return false
        }
        
        let totalAmountToConsume = amountInBaseUnit.value * measurementPerUnit.value
        let availableAmount = totalMeasurement - used
        
        guard availableAmount >= totalAmountToConsume else {
            return false
        }
        
        used += totalAmountToConsume
        updatedAt = Date()
        return true
    }
    
    mutating func restock(quantity: Double) {
        self.quantity += max(0, quantity)
        updatedAt = Date()
    }
    
    mutating func resetUsage() {
        used = 0
        updatedAt = Date()
    }
    
    // MARK: - Mutating Methods
    
    mutating func updateQuantity(_ newQuantity: Double) {
        quantity = max(0, newQuantity)
        updatedAt = Date()
    }
    
    mutating func updateMinQuantity(_ newMinQuantity: Double) {
        minQuantity = max(0, newMinQuantity)
        updatedAt = Date()
    }
    
    mutating func updateCostPrice(_ newCostPrice: Double) {
        costPrice = max(0, newCostPrice)
        updatedAt = Date()
    }
    
    mutating func updateExpiryDate(_ newExpiryDate: Date?) {
        expiryDate = newExpiryDate
        updatedAt = Date()
    }
    
    // MARK: - Helper Methods
    func canBeUsed(amount: Measurement) -> Bool {
        guard let amountInBaseUnit = amount.converted(to: measurementPerUnit.unit) else {
            return false
        }
        
        let totalAmountNeeded = amountInBaseUnit.value * measurementPerUnit.value
        let availableAmount = totalMeasurement - used
        
        return availableAmount >= totalAmountNeeded
    }
    
    func getAvailableAmount() -> Double {
        return max(0, totalMeasurement - used)
    }
    
    func getUsagePercentage() -> Double {
        guard totalMeasurement > 0 else { return 0 }
        return (used / totalMeasurement) * 100
    }
    
    func getDaysUntilExpiry() -> Int? {
        guard let expiryDate = expiryDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: expiryDate).day
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
        case .gram: return "Gram"
        case .kilogram: return "Kilogram"
        case .milliliter: return "Mililít"
        case .liter: return "Lít"
        case .piece: return "Miếng"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .gram: return "g"
        case .kilogram: return "kg"
        case .milliliter: return "ml"
        case .liter: return "l"
        case .piece: return "cái"
        }
    }
    
    var icon: String {
        switch self {
        case .gram, .kilogram: return "scalemass"
        case .milliliter, .liter: return "drop"
        case .piece: return "cube"
        }
    }
    
    func isCompatible(with other: MeasurementUnit) -> Bool {
        switch (self, other) {
        case (.gram, .kilogram), (.kilogram, .gram),
            (.milliliter, .liter), (.liter, .milliliter):
            return true
        default:
            return self == other
        }
    }
    
    var baseUnit: MeasurementUnit {
        switch self {
        case .gram, .kilogram: return .gram
        case .milliliter, .liter: return .milliliter
        case .piece: return .piece
        }
    }
    
    func convert(_ value: Double, to targetUnit: MeasurementUnit) -> Double? {
        guard isCompatible(with: targetUnit) else { return nil }
        
        if self == targetUnit { return value }
        
        switch (self, targetUnit) {
        case (.gram, .kilogram):
            return value / 1000
        case (.kilogram, .gram):
            return value * 1000
        case (.milliliter, .liter):
            return value / 1000
        case (.liter, .milliliter):
            return value * 1000
        default:
            return value
        }
    }
}

// MARK: - Validation
extension IngredientUsage {
    enum ValidationError: LocalizedError {
        case invalidName
        case invalidQuantity
        case invalidMinQuantity
        case invalidCostPrice
        case invalidCategory
        case invalidDescription
        case invalidSupplier
        case invalidBarcode
        case invalidLocation
        case duplicateName
        
        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "Tên nguyên liệu không hợp lệ"
            case .invalidQuantity:
                return "Số lượng không hợp lệ"
            case .invalidMinQuantity:
                return "Số lượng tối thiểu không hợp lệ"
            case .invalidCostPrice:
                return "Giá thành không hợp lệ"
            case .invalidCategory:
                return "Danh mục không hợp lệ"
            case .invalidDescription:
                return "Mô tả không hợp lệ"
            case .invalidSupplier:
                return "Nhà cung cấp không hợp lệ"
            case .invalidBarcode:
                return "Mã vạch không hợp lệ"
            case .invalidLocation:
                return "Vị trí lưu trữ không hợp lệ"
            case .duplicateName:
                return "Tên nguyên liệu đã tồn tại"
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
        
        // Validate quantity
        guard quantity >= 0 else {
            throw ValidationError.invalidQuantity
        }
        
        guard quantity <= 1000000 else { // Max 1 million units
            throw ValidationError.invalidQuantity
        }
        
        // Validate min quantity
        guard minQuantity >= 0 else {
            throw ValidationError.invalidMinQuantity
        }
        
        guard minQuantity <= quantity else {
            throw ValidationError.invalidMinQuantity
        }
        
        // Validate cost price
        guard costPrice >= 0 else {
            throw ValidationError.invalidCostPrice
        }
        
        guard costPrice <= 10000000 else { // Max 10 million VND per unit
            throw ValidationError.invalidCostPrice
        }
    }
    
    static func validateName(_ name: String, existingIngredients: [IngredientUsage], excludeId: String? = nil) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidName
        }
        
        // Check for duplicate names
        let duplicateExists = existingIngredients.contains { ingredient in
            ingredient.name.lowercased() == trimmedName.lowercased() && ingredient.id != excludeId
        }
        
        if duplicateExists {
            throw ValidationError.duplicateName
        }
    }
}
