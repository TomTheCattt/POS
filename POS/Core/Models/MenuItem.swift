//
//  MenuItem.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

struct MenuItem: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let description: String?
    let price: Double
    let category: String
    let imageURL: URL?
    let ingredients: [IngredientUsage]?
    let options: [MenuItemOption]?
    let isAvailable: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "description": description as Any,
            "price": price,
            "category": category,
            "imageURL": imageURL?.absoluteString as Any,
            "isAvailable": isAvailable,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        
        if let ingredients = ingredients {
            dict["ingredients"] = ingredients.map { $0.dictionary }
        }
        
        if let options = options {
            dict["options"] = options.map { $0.dictionary }
        }
        
        return dict
    }
}

struct IngredientUsage: Codable {
    let inventoryItemID: String
    let quantity: Double
    let unit: String
    
    var dictionary: [String: Any] {
        [
            "inventoryItemID": inventoryItemID,
            "quantity": quantity,
            "unit": unit
        ]
    }
}

struct MenuItemOption: Codable {
    let name: String
    let choices: [MenuItemChoice]
    let isRequired: Bool
    let maxChoices: Int
    
    var dictionary: [String: Any] {
        [
            "name": name,
            "choices": choices.map { $0.dictionary },
            "isRequired": isRequired,
            "maxChoices": maxChoices
        ]
    }
}

struct MenuItemChoice: Codable {
    let name: String
    let price: Double
    
    var dictionary: [String: Any] {
        [
            "name": name,
            "price": price
        ]
    }
}

enum MeasurementUnit: String, Codable, CaseIterable, Hashable {
    case gram
    case kilogram
    case milliliter
    case liter
    case piece
}

extension MenuItem {
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["name"] as? String,
              let price = data["price"] as? Double,
              let category = data["category"] as? String,
              let isAvailable = data["isAvailable"] as? Bool,
              let ingredientsData = data["ingredients"] as? [[String: Any]]
        else {
            return nil
        }

        let ingredients: [IngredientUsage] = ingredientsData.compactMap { dict in
            guard let inventoryItemID = dict["inventoryItemID"] as? String,
                  let quantity = dict["quantity"] as? Double,
                  let unitRaw = dict["unit"] as? String,
                  let unit = MeasurementUnit(rawValue: unitRaw) else {
                return IngredientUsage(inventoryItemID: "Error", quantity: 0, unit: "Error")
            }
            return IngredientUsage(inventoryItemID: inventoryItemID, quantity: quantity, unit: unit.rawValue)
        }

        self.id = document.documentID
        self.name = name
        self.price = price
        self.category = category
        self.ingredients = ingredients
        self.isAvailable = isAvailable

        if let imageURLString = data["imageURL"] as? String, let url = URL(string: imageURLString) {
            self.imageURL = url
        } else {
            self.imageURL = nil
        }

        if let description = data["description"] as? String {
            self.description = description
        } else {
            self.description = nil
        }

        if let optionsData = data["options"] as? [[String: Any]] {
            self.options = optionsData.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let choicesData = dict["choices"] as? [[String: Any]],
                      let isRequired = dict["isRequired"] as? Bool,
                      let maxChoices = dict["maxChoices"] as? Int
                else {
                    return nil
                }
                let choices: [MenuItemChoice] = choicesData.compactMap { choiceDict in
                    guard let choiceName = choiceDict["name"] as? String,
                          let choicePrice = choiceDict["price"] as? Double
                    else {
                        return nil
                    }
                    return MenuItemChoice(name: choiceName, price: choicePrice)
                }
                return MenuItemOption(name: name, choices: choices, isRequired: isRequired, maxChoices: maxChoices)
            }
        } else {
            self.options = nil
        }

        if let createdAt = data["createdAt"] as? Timestamp {
            self.createdAt = createdAt.dateValue()
        } else {
            self.createdAt = Date()
        }

        if let updatedAt = data["updatedAt"] as? Timestamp {
            self.updatedAt = updatedAt.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
}

