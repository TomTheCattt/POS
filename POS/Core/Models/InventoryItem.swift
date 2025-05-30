//
//  InventoryItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct InventoryItem: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Properties
    @DocumentID var id: String?
    let name: String
    var quantity: Double
    let unit: MeasurementUnit
    let measurement: Measurement // Định lượng cho 1 đơn vị
    let minQuantity: Double
    let costPrice: Double
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    var isLowStock: Bool {
        totalMeasurement <= minQuantity * measurement.value
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
    
    // Tổng định lượng thực tế
    var totalMeasurement: Double {
        quantity * measurement.value
    }
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        name: String,
        quantity: Double,
        unit: MeasurementUnit,
        measurement: Measurement,
        minQuantity: Double,
        costPrice: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.measurement = measurement
        self.minQuantity = minQuantity
        self.costPrice = costPrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Dictionary Representation
    var dictionary: [String: Any] {
        [
            "name": name,
            "quantity": quantity,
            "unit": unit.rawValue,
            "measurement": measurement.dictionary,
            "minQuantity": minQuantity,
            "costPrice": costPrice,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    static func == (lhs: InventoryItem, rhs: InventoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Measurement Structure
struct Measurement: Codable, Equatable {
    let value: Double
    let unit: MeasurementUnit
    
    var dictionary: [String: Any] {
        [
            "value": value,
            "unit": unit.rawValue
        ]
    }
}

// MARK: - Supporting Types
extension InventoryItem {
    enum StockStatus: String, Codable {
        case inStock = "inStock"
        case lowStock = "lowStock"
        case outOfStock = "outOfStock"
        
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

// MARK: - Firestore Extensions
extension InventoryItem {
    init?(document: DocumentSnapshot) {
        guard 
            let data = document.data(),
            let name = data["name"] as? String,
            let quantity = data["quantity"] as? Double,
            let unitString = data["unit"] as? String,
            let unit = MeasurementUnit(rawValue: unitString),
            let measurementData = data["measurement"] as? [String: Any],
            let measurementValue = measurementData["value"] as? Double,
            let measurementUnitString = measurementData["unit"] as? String,
            let measurementUnit = MeasurementUnit(rawValue: measurementUnitString),
            let minQuantity = data["minQuantity"] as? Double,
            let costPrice = data["costPrice"] as? Double
        else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.measurement = Measurement(value: measurementValue, unit: measurementUnit)
        self.minQuantity = minQuantity
        self.costPrice = costPrice
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    // Helper method để lấy số lượng theo đơn vị đo cụ thể
    func getMeasurementQuantity(in targetUnit: MeasurementUnit) -> Double {
        guard measurement.unit != targetUnit else {
            return totalMeasurement
        }
        
        // Chuyển đổi giữa các đơn vị
        switch (measurement.unit, targetUnit) {
        case (.gram, .kilogram), (.milliliter, .liter):
            return totalMeasurement / 1000
        case (.kilogram, .gram), (.liter, .milliliter):
            return totalMeasurement * 1000
        default:
            return totalMeasurement
        }
    }
}
