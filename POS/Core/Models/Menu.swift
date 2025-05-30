//import Foundation
//import FirebaseFirestore
//
//struct Menu: Codable, Identifiable {
//    @DocumentID var id: String?
//    let categories: [Category]
//    let createdAt: Date
//    let updatedAt: Date
//    
//    var dictionary: [String: Any] {
//        let dict: [String: Any] = [
//            "createdAt": createdAt,
//            "updatedAt": updatedAt,
//            "categories": categories.map { $0.dictionary }
//        ]
//        return dict
//    }
//}
//
//struct Category: Codable, Identifiable {
//    let id: String
//    let categoryName: String
//    let items: [MenuItem]
//    
//    var dictionary: [String: Any] {
//        let dict: [String: Any] = [
//            "id": id,
//            "categoryName": categoryName,
//            "items": items.map { $0.dictionary }
//        ]
//        return dict
//    }
//}
//
//extension Menu {
//    init?(document: DocumentSnapshot) {
//        guard let data = document.data(),
//              let categoriesData = data["categories"] as? [[String: Any]],
//              let createdAtTimestamp = data["createdAt"] as? Timestamp,
//              let updatedAtTimestamp = data["updatedAt"] as? Timestamp
//        else {
//            return nil
//        }
//        
//        let categories: [Category] = categoriesData.compactMap { dict in
//            guard let id = dict["id"] as? String,
//                  let categoryName = dict["categoryName"] as? String,
//                  let itemsData = dict["items"] as? [[String: Any]]
//            else {
//                return nil
//            }
//            
//            // Parse items
//            let items: [MenuItem] = itemsData.compactMap { itemDict in
//                guard let id = itemDict["id"] as? String,
//                      let name = itemDict["name"] as? String,
//                      let price = itemDict["price"] as? Double,
//                      let category = itemDict["category"] as? String,
//                      let isAvailable = itemDict["isAvailable"] as? Bool
//                else {
//                    return nil
//                }
//                
//                // Parse ingredients
//                let ingredients: [IngredientUsage]? = (itemDict["ingredients"] as? [[String: Any]])?.compactMap { ingredientDict in
//                    guard let inventoryItemID = ingredientDict["inventoryItemID"] as? String,
//                          let quantity = ingredientDict["quantity"] as? Double,
//                          let unit = ingredientDict["unit"] as? String
//                    else {
//                        return nil
//                    }
//                    return IngredientUsage(inventoryItemID: inventoryItemID, quantity: quantity, unit: unit)
//                }
//                
//                // Parse dates
//                let createdAt = (itemDict["createdAt"] as? Timestamp)?.dateValue() ?? Date()
//                let updatedAt = (itemDict["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
//                
//                // Parse imageURL
//                var itemImageURL: URL? = nil
//                if let urlString = itemDict["imageURL"] as? String {
//                    itemImageURL = URL(string: urlString)
//                }
//                
//                return MenuItem(
//                    id: itemDict["id"] as? String,
//                    name: name,
//                    price: price,
//                    category: category,
//                    ingredients: ingredients,
//                    isAvailable: isAvailable,
//                    imageURL: itemImageURL,
//                    createdAt: createdAt,
//                    updatedAt: updatedAt
//                )
//            }
//            
//            return Category(
//                id: id,
//                categoryName: categoryName,
//                items: items
//            )
//        }
//        
//        self.id = document.documentID
//        self.categories = categories
//        self.createdAt = createdAtTimestamp.dateValue()
//        self.updatedAt = updatedAtTimestamp.dateValue()
//    }
//} 
