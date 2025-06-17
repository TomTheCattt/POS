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
    let items: [OrderItem]
    let discount: Double?
    let totalAmount: Double
    let paymentMethod: PaymentMethod
    let customer: Customer?
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Dictionary Representation
//    var dictionary: [String: Any] {
//        var dict: [String: Any] = [
//                "items": items.map { $0.dictionary },
//                "totalAmount": totalAmount,
//                "paymentMethod": paymentMethod.rawValue,
//                "createdAt": createdAt,
//                "updatedAt": updatedAt
//            ]
//        
//        if let customer = customer {
//            dict["customer"] = customer.dictionary
//        }
//        return dict
//    }

    var formattedId: String {
        if let id = id {
            // Lấy 6 ký tự cuối của ID
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

    // MARK: - Dictionary Representation
//    var dictionary: [String: Any] {
//        var dict: [String: Any] = [
//            "id": id,
//            "menuItemId": menuItemId,
//            "name": name,
//            "quantity": quantity,
//            "price": price,
//            "temperature": temperature.rawValue,
//            "consumption": consumption.rawValue
//        ]
//
//        if let note = note {
//            dict["note"] = note
//        }
//
//        return dict
//    }
}

//extension Order {
//    init?(document: DocumentSnapshot) {
//        guard let data = document.data(),
//              let totalAmount = data["totalAmount"] as? Double,
//              let paymentMethodRaw = data["paymentMethod"] as? String,
//              let paymentMethod = PaymentMethod(rawValue: paymentMethodRaw),
//              let itemsData = data["items"] as? [[String: Any]],
//              let customerData = data["customer"] as? [String: Any],
//              let customer = Customer(dictionary: customerData),
//              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
//              let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
//        else {
//            return nil
//        }
//
//        let items: [OrderItem] = itemsData.compactMap { dict in
//            guard let id = dict["id"] as? String,
//                  let menuItemId = dict["menuItemId"] as? String,
//                  let name = dict["name"] as? String,
//                  let quantity = dict["quantity"] as? Int,
//                  let price = dict["price"] as? Double,
//                  let temperatureRaw = dict["temperature"] as? String,
//                  let temperature = TemperatureOption(rawValue: temperatureRaw),
//                  let consumptionRaw = dict["consumption"] as? String,
//                  let consumption = ConsumptionOption(rawValue: consumptionRaw)
//            else {
//                return nil
//            }
//
//            let note = dict["note"] as? String
//
//            return OrderItem(id: id, menuItemId: menuItemId, name: name, quantity: quantity, price: price, note: note, temperature: temperature, consumption: consumption)
//        }
//
//        self.id = document.documentID
//        self.items = items
//        self.totalAmount = totalAmount
//        self.paymentMethod = paymentMethod
//        self.createdAt = createdAt
//        self.updatedAt = updatedAt
//        self.customer = customer
//    }
//}
