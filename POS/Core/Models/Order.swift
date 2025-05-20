//
//  Order.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

enum PaymentMethod: String, Codable, CaseIterable {
    case cash, card, bankTransfer
    
    var description: String {
        switch self {
        case .cash:
            return "Tiền mặt"
        case .card:
            return "Thẻ"
        case .bankTransfer:
            return "Chuyển khoản"
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

struct Order: Codable, Identifiable {
    @DocumentID var id: String?
    let items: [OrderItem]
    let subTotal: Double
    let discount: Double
    let total: Double
    let paymentMethod: PaymentMethod
    let createdAt: Date
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "items": items.map { $0.dictionary },
            "subTotal": subTotal,
            "discount": discount,
            "total": total,
            "paymentMethod": paymentMethod.description,
            "createdAt": createdAt
        ]
        
        return dict
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let name: String
    var quantity: Int
    let price: Double
    var note: String?
    var temprature: String
    var consumption: String
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "quantity": quantity,
            "price": price,
            "temprature": temprature,
            "consumption": consumption
        ]

        if let note = note {
            dict["note"] = note
        }

        return dict
    }
}

extension Order {
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let subTotal = data["subTotal"] as? Double,
              let total = data["total"] as? Double,
              let discount = data["discount"] as? Double,
              let paymentMethodRaw = data["paymentMethod"] as? String,
              let paymentMethod = PaymentMethod(rawValue: paymentMethodRaw),
              let itemsData = data["items"] as? [[String: Any]],
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        let items: [OrderItem] = itemsData.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let quantity = dict["quantity"] as? Int,
                  let price = dict["price"] as? Double,
                  let tempRaw = dict["temprature"] as? String,
                  let temprature = TemperatureOption(rawValue: tempRaw),
                  let consumpRaw = dict["consumption"] as? String,
                  let consumption = ConsumptionOption(rawValue: consumpRaw)
            else {
                return OrderItem(id: "Error", name: "Error", quantity: 0, price: 0, temprature: "Error", consumption: "Error")
            }

            return OrderItem(
                id: id,
                name: name,
                quantity: quantity,
                price: price,
                note: dict["note"] as? String,
                temprature: temprature.rawValue,
                consumption: consumption.rawValue
            )
        }

        self.id = document.documentID
        self.items = items
        self.subTotal = subTotal
        self.total = total
        self.discount = discount
        self.paymentMethod = paymentMethod
        self.createdAt = createdAt
    }
}


