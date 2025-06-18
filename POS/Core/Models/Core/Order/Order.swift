//
//  Order.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Tiền mặt"
    case card = "Thẻ"
    case bankTransfer = "Chuyển khoản"
}

enum TemperatureOption: String, CaseIterable, Codable {
    case hot = "Nóng"
    case cold = "Lạnh"
}

enum ConsumptionOption: String, CaseIterable, Codable {
    case stay = "Tại chỗ"
    case takeAway = "Mang đi"
}

struct Order: Codable, Identifiable, Hashable {
    // MARK: - Properties
    @DocumentID var id: String?
    let shopId: String
    let items: [OrderItem]
    let discount: Double?
    let totalAmount: Double
    let paymentMethod: PaymentMethod
    let customer: Customer?
    let createdAt: Date
    var updatedAt: Date

    var formattedId: String {
        if let id = id {
            let shortId = String(id.suffix(6)).uppercased()
            return "#\(shortId)"
        }
        return "#N/A"
    }
}

struct OrderItem: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Properties
    let id: String
    let menuItemId: String
    let name: String
    var quantity: Int
    let price: Double
    var note: String?
    let temperature: TemperatureOption
    let consumption: ConsumptionOption

    // MARK: - Computed Properties
    var subtotal: Double {
        price * Double(quantity)
    }
}
