//
//  Order.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

enum PaymentMethod: String, Codable, CaseIterable {
    case cash
    case bankTransfer
    case card
    
    var title: String {
        switch self {
        case .cash:
            return "Cash"
        case .bankTransfer:
            return "Bank Transfer"
        case .card:
            return "Card"
        }
    }
}

enum TemperatureOption: String, CaseIterable, Codable {
    case hot = "Hot"
    case cold = "Cold"
}

enum ConsumptionOption: String, CaseIterable, Codable {
    case stay = "Stay"
    case takeAway = "Take Away"
}

struct Order: Codable, Identifiable, Hashable {
    var id: String
    var items: [OrderItem]
    var createdAt: Date
    var createdBy: String
    var totalAmount: Double
    var discount: Double
    var paymentMethod: PaymentMethod
}

struct OrderItem: Codable, Identifiable, Hashable {
    var id: String
    var menuItemId: String
    var quantity: Int
    var note: String?
    var temprature: TemperatureOption
    var consumption: ConsumptionOption
}


