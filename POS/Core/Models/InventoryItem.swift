//
//  InventoryItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

struct InventoryItem: Codable, Identifiable, Hashable  {
    var id: String
    var name: String
    var quantity: Double
    var unit: MeasurementUnit
    var costPerUnit: Double
    var minThreshold: Double?
    var lastUpdated: Date?
}

enum MeasurementUnit: String, Codable, CaseIterable {
    case gram, kilogram, milliliter, liter, piece
}

extension MeasurementUnit {
    var localizedName: String {
        switch self {
        case .gram: return NSLocalizedString("measure.gram", comment: "")
        case .kilogram: return NSLocalizedString("measure.kilogram", comment: "")
        case .milliliter: return NSLocalizedString("measure.milliliter", comment: "")
        case .liter: return NSLocalizedString("measure.liter", comment: "")
        case .piece: return NSLocalizedString("measure.piece", comment: "")
        }
    }
}
