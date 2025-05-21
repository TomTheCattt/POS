import Foundation

enum DatabaseCollection: String {
    case users = "users"
    case shops = "shops"
    case menu = "menu"
    case orders = "orders"
    case inventory = "inventory"
    
    // Tạo path cho subcollections
    static func shopPath(userId: String, shopId: String) -> String {
        return "\(DatabaseCollection.users.rawValue)/\(userId)/\(DatabaseCollection.shops.rawValue)/\(shopId)"
    }
    
    static func menuPath(userId: String, shopId: String) -> String {
        return "\(shopPath(userId: userId, shopId: shopId))/\(DatabaseCollection.menu.rawValue)"
    }
    
    static func ordersPath(userId: String, shopId: String) -> String {
        return "\(shopPath(userId: userId, shopId: shopId))/\(DatabaseCollection.orders.rawValue)"
    }
    
    static func inventoryPath(userId: String, shopId: String) -> String {
        return "\(shopPath(userId: userId, shopId: shopId))/\(DatabaseCollection.inventory.rawValue)"
    }
} 