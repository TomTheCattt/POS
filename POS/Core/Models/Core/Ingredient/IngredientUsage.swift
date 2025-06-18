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
}
