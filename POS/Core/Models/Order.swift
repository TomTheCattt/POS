//
//  Order.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

enum PaymentMethod: String, Codable, CaseIterable {
    case cash
    case card
    case bankTransfer
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
    let totalAmount: Double
    let paymentMethod: PaymentMethod
    let createdAt: Date
    var updatedAt: Date
    
    var dictionary: [String: Any] {
        [
            "items": items.map { $0.dictionary },
            "totalAmount": totalAmount,
            "paymentMethod": paymentMethod.rawValue,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let name: String
    var quantity: Int
    let price: Double
    var note: String?
    let temperature: TemperatureOption
    let consumption: ConsumptionOption
    
    var dictionary: [String: Any] {
        [
            "name": name,
            "quantity": quantity,
            "price": price,
            "temperature": temperature,
            "consumption": consumption
        ]
    }
}

extension Order {
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let totalAmount = data["totalAmount"] as? Double,
              let paymentMethodRaw = data["paymentMethod"] as? String,
              let paymentMethod = PaymentMethod(rawValue: paymentMethodRaw),
              let itemsData = data["items"] as? [[String: Any]],
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        let items: [OrderItem] = itemsData.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let quantity = dict["quantity"] as? Int,
                  let price = dict["price"] as? Double,
                  let note = dict["note"] as? String,
                  let temperatureRaw = data["temperature"] as? String,
                  let temperature = TemperatureOption(rawValue: temperatureRaw),
                  let consumptionRaw = data["consumption"] as? String,
                  let consumption = ConsumptionOption(rawValue: consumptionRaw)
            else {
                return nil
            }

            return OrderItem(id: id, name: name, quantity: quantity, price: price, note: note, temperature: temperature, consumption: consumption)
        }

        self.id = document.documentID
        self.items = items
        self.totalAmount = totalAmount
        self.paymentMethod = paymentMethod
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


