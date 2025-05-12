//
//  MenuItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

struct MenuItem: Codable, Identifiable, Hashable  {
    var id: String
    var name: String
    var price: Double
    var category: String
    var ingredients: [IngredientUsage]
    var imageURL: URL?
    var isAvailable: Bool
}

struct IngredientUsage: Codable, Hashable  {
    var inventoryItemID: String
    var quantity: Double
    var unit: MeasurementUnit
}

