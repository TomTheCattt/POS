import Foundation

enum DatabaseCollection: String {
    case users, shops, orders, menu, inventory, ingredientsUsage

    enum PathType {
        case collection
        case document
        case subcollection(parentId: String)
        case nestedDocument(parentId: String, childId: String)
        // Thêm case cho nested subcollection (shop's collections)
        case nestedSubcollection(userId: String, shopId: String)
        case deepNestedDocument(userId: String, shopId: String, itemId: String)
    }

    func path(for type: PathType) -> String {
        switch (self, type) {
        // USERS cases
        case (.users, .collection):
            return "users"
        case (.users, .document):
            return "users"
        case (.users, .subcollection(_)):
            return "Invalid: users don't have subcollections"
        case (.users, .nestedDocument(_, _)):
            return "Invalid: users don't have nested documents"
            
        // SHOPS cases
        case (.shops, .collection):
            return "Invalid: shops must be under a user"
        case (.shops, .document):
            return "Invalid: shops must be under a user"
        case (.shops, .subcollection(let userId)):
            return "users/\(userId)/shops"
        case (.shops, .nestedDocument(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)"
            
        // ORDERS cases
        case (.orders, .collection):
            return "Invalid: orders must be under a shop"
        case (.orders, .document):
            return "Invalid: orders must be under a shop"
        case (.orders, .subcollection(_)):
            return "Invalid: need userId for orders path"
        case (.orders, .nestedDocument(_, _)):
            return "Invalid: need userId for orders path"
        case (.orders, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/orders"
        case (.orders, .deepNestedDocument(let userId, let shopId, let orderId)):
            return "users/\(userId)/shops/\(shopId)/orders/\(orderId)"
            
        // MENU cases
        case (.menu, .collection):
            return "Invalid: menu must be under a shop"
        case (.menu, .document):
            return "Invalid: menu must be under a shop"
        case (.menu, .subcollection(_)):
            return "Invalid: need userId for menu path"
        case (.menu, .nestedDocument(_, _)):
            return "Invalid: need userId for menu path"
        case (.menu, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/menu"
        case (.menu, .deepNestedDocument(let userId, let shopId, let menuItemId)):
            return "users/\(userId)/shops/\(shopId)/menu/\(menuItemId)"
            
        // INVENTORY cases
        case (.inventory, .collection):
            return "Invalid: inventory must be under a shop"
        case (.inventory, .document):
            return "Invalid: inventory must be under a shop"
        case (.inventory, .subcollection(_)):
            return "Invalid: need userId for inventory path"
        case (.inventory, .nestedDocument(_, _)):
            return "Invalid: need userId for inventory path"
        case (.inventory, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/inventories"
        case (.inventory, .deepNestedDocument(let userId, let shopId, let inventoryItemId)):
            return "users/\(userId)/shops/\(shopId)/inventories/\(inventoryItemId)"
            
        // INGREDIENTS USAGE cases
        case (.ingredientsUsage, .collection):
            return "Invalid: inventory must be under a shop"
        case (.ingredientsUsage, .document):
            return "Invalid: inventory must be under a shop"
        case (.ingredientsUsage, .subcollection(_)):
            return "Invalid: need userId for inventory path"
        case (.ingredientsUsage, .nestedDocument(_, _)):
            return "Invalid: need userId for inventory path"
        case (.ingredientsUsage, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/ingredientsUsage"
        case (.ingredientsUsage, .deepNestedDocument(let userId, let shopId, let ingredientsUsageId)):
            return "users/\(userId)/shops/\(shopId)/ingredientsUsage/\(ingredientsUsageId)"
            
        default:
            return "Invalid path combination"
        }
    }
}

// MARK: - Usage Examples
extension DatabaseCollection {
    static func getUsersCollection() -> String {
        return DatabaseCollection.users.path(for: .collection)
    }
    
    static func getUserDocument(userId: String) -> String {
        return DatabaseCollection.users.path(for: .document)
    }
    
    static func getShopsCollection(userId: String) -> String {
        return DatabaseCollection.shops.path(for: .subcollection(parentId: userId))
    }
    
    static func getShopDocument(userId: String, shopId: String) -> String {
        return DatabaseCollection.shops.path(for: .nestedDocument(parentId: userId, childId: shopId))
    }
    
    static func getOrdersCollection(userId: String, shopId: String) -> String {
        return DatabaseCollection.orders.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getOrderDocument(userId: String, shopId: String, orderId: String) -> String {
        return DatabaseCollection.orders.path(for: .deepNestedDocument(userId: userId, shopId: shopId, itemId: orderId))
    }
    
    static func getMenuCollection(userId: String, shopId: String) -> String {
        return DatabaseCollection.menu.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getMenuItemDocument(userId: String, shopId: String, menuItemId: String) -> String {
        return DatabaseCollection.menu.path(for: .deepNestedDocument(userId: userId, shopId: shopId, itemId: menuItemId))
    }
    
    static func getInventoryCollection(userId: String, shopId: String) -> String {
        return DatabaseCollection.inventory.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getInventoryItemDocument(userId: String, shopId: String, inventoryItemId: String) -> String {
        return DatabaseCollection.inventory.path(for: .deepNestedDocument(userId: userId, shopId: shopId, itemId: inventoryItemId))
    }
    
    static func getIngredientsCollection(userId: String, shopId: String) -> String {
        return DatabaseCollection.inventory.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getIngredientItemDocument(userId: String, shopId: String, ingredientsId: String) -> String {
        return DatabaseCollection.ingredientsUsage.path(for: .deepNestedDocument(userId: userId, shopId: shopId, itemId: ingredientsId))
    }
}


