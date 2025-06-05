import Foundation

enum DatabaseCollection: String {
    case users, shops, orders, menu, menuItems, recipes, ingredientsUsage
    
    enum PathType {
        // users
        case collection
        
        // specific user
        case document
        
        // shops
        case subcollection(parentId: String)
        
        //specific shop
        case nestedDocument(parentId: String, childId: String)
        
        // Thêm case cho nested subcollection (shop's collections)
        
        // menu, recipes, ingredientsUsage
        case nestedSubcollection(userId: String, shopId: String)
        
        // specific menu || recipe || ingredientUsage
        case deepNestedDocument(userId: String, shopId: String, optionId: String)
        
        // deep nested subcollection (menu's collections)
        
        // menu items
        case deepNestedSubCollection(userId: String, shopId: String, optionId: String)
        
        // menu item
        case deepNestedSubCollectionDocument(userId: String, shopId: String, optionId: String, menuItemId: String)
    }
    
    func path(for type: PathType) -> String {
        switch (self, type) {
            // USERS cases
        case (.users, .collection):
            return "users"
        case (.users, .document):
            return "users"
            
            // SHOPS cases
        case (.shops, .subcollection(let userId)):
            return "users/\(userId)/shops"
        case (.shops, .nestedDocument(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)"
            
            // ORDERS cases
        case (.orders, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/orders"
        case (.orders, .deepNestedDocument(let userId, let shopId, let orderId)):
            return "users/\(userId)/shops/\(shopId)/orders/\(orderId)"
            
            // MENU cases
        case (.menu, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/menu"
        case (.menu, .deepNestedDocument(let userId, let shopId, let menuId)):
            return "users/\(userId)/shops/\(shopId)/menu/\(menuId)"
            
            // RECIPE cases
        case (.recipes, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/recipes"
        case (.recipes, .deepNestedDocument(let userId, let shopId, let recipeId)):
            return "users/\(userId)/shops/\(shopId)/recipes/\(recipeId)"
            
            // INGREDIENTS USAGE cases
        case (.ingredientsUsage, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/ingredientsUsage"
        case (.ingredientsUsage, .deepNestedDocument(let userId, let shopId, let ingredientsUsageId)):
            return "users/\(userId)/shops/\(shopId)/ingredientsUsage/\(ingredientsUsageId)"
            
            // MENU ITEMS cases
        case (.menuItems, .deepNestedSubCollection(let userId, let shopId, let menuId)):
            return "users/\(userId)/shops/\(shopId)/menu/\(menuId)/menuItems"
        case (.menuItems, .deepNestedSubCollectionDocument(let userId, let shopId, let menuId, let menuItemId)):
            return "users/\(userId)/shops/\(shopId)/menu/\(menuId)/menuItems/\(menuItemId)"
            
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
        return DatabaseCollection.orders.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: orderId))
    }
    
    static func getMenuCollection(userId: String, shopId: String) -> String {
        return DatabaseCollection.menu.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getMenuDocument(userId: String, shopId: String, menuItemId: String) -> String {
        return DatabaseCollection.menu.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: menuItemId))
    }
    
    static func getRecipesCollection(userId: String, shopId: String) -> String {
        return DatabaseCollection.recipes.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getRecipeDocument(userId: String, shopId: String, recipeId: String) -> String {
        return DatabaseCollection.recipes.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: recipeId))
    }
    
    static func getIngredientsCollection(userId: String, shopId: String) -> String {
        return DatabaseCollection.ingredientsUsage.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getIngredientItemDocument(userId: String, shopId: String, ingredientsId: String) -> String {
        return DatabaseCollection.ingredientsUsage.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: ingredientsId))
    }
    
    static func getMenuItemsCollection(userId: String, shopId: String, menuId: String) -> String {
        return DatabaseCollection.menu.path(for: .deepNestedSubCollection(userId: userId, shopId: shopId, optionId: menuId))
    }
    
    static func getMenuItemDocument(userId: String, shopId: String, menuId: String, menuItemId: String) -> String {
        return DatabaseCollection.menu.path(for: .deepNestedSubCollectionDocument(userId: userId, shopId: shopId, optionId: menuId, menuItemId: menuItemId))
    }
}


