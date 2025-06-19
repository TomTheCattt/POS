import Foundation

enum DatabaseCollection: String {
    case users, shops, orders, menu, menuItems, ingredientsUsage, staff, customer, revenueRecord, expense
    
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
        
        // menu, staff, ingredientsUsage
        case nestedSubcollection(userId: String, shopId: String)
        
        // specific menu || staff || ingredientUsage || customer || revenue record || expense
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
            
            // INGREDIENTS USAGE cases
        case (.ingredientsUsage, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/ingredientsUsage"
        case (.ingredientsUsage, .deepNestedDocument(let userId, let shopId, let ingredientsUsageId)):
            return "users/\(userId)/shops/\(shopId)/ingredientsUsage/\(ingredientsUsageId)"
            
            // STAFF cases
        case (.staff, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/staff"
        case (.staff, .deepNestedDocument(let userId, let shopId, let staffId)):
            return "users/\(userId)/shops/\(shopId)/staff/\(staffId)"
            
            // CUSTOMER cases
        case (.customer, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/customers"
        case (.customer, .deepNestedDocument(let userId, let shopId, let customerId)):
            return "users/\(userId)/shops/\(shopId)/customers/\(customerId)"
            
            // REVENUE RECORD cases
        case (.revenueRecord, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/revenueRecords"
        case (.revenueRecord, .deepNestedDocument(let userId, let shopId, let revenueRecordId)):
            return "users/\(userId)/shops/\(shopId)/revenueRecords/\(revenueRecordId)"
            
            // EXPENSE cases
        case (.expense, .nestedSubcollection(let userId, let shopId)):
            return "users/\(userId)/shops/\(shopId)/expenses"
        case (.expense, .deepNestedDocument(let userId, let shopId, let expenseId)):
            return "users/\(userId)/shops/\(shopId)/expenses/\(expenseId)"
            
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
        guard !userId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.users.path(for: .document)
    }
    
    static func getShopsCollection(userId: String) -> String {
        guard !userId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.shops.path(for: .subcollection(parentId: userId))
    }
    
    static func getShopDocument(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.shops.path(for: .nestedDocument(parentId: userId, childId: shopId))
    }
    
    static func getOrdersCollection(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.orders.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getOrderDocument(userId: String, shopId: String, orderId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !orderId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.orders.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: orderId))
    }
    
    static func getMenuCollection(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.menu.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getMenuDocument(userId: String, shopId: String, menuItemId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !menuItemId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.menu.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: menuItemId))
    }
    
    static func getStaffsCollection(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.staff.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getStaffDocument(userId: String, shopId: String, staffId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !staffId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.staff.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: staffId))
    }
    
    static func getIngredientsCollection(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.ingredientsUsage.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getIngredientItemDocument(userId: String, shopId: String, ingredientsId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !ingredientsId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.ingredientsUsage.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: ingredientsId))
    }
    
    static func getMenuItemsCollection(userId: String, shopId: String, menuId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !menuId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.menu.path(for: .deepNestedSubCollection(userId: userId, shopId: shopId, optionId: menuId))
    }
    
    static func getMenuItemDocument(userId: String, shopId: String, menuId: String, menuItemId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !menuItemId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.menu.path(for: .deepNestedSubCollectionDocument(userId: userId, shopId: shopId, optionId: menuId, menuItemId: menuItemId))
    }
    
    static func getCustomersCollection(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.customer.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getCustomerDocument(userId: String, shopId: String, customerId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !customerId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.customer.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: customerId))
    }
    
    static func getRevenueRecordsCollection(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.revenueRecord.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getRevenueRecordDocument(userId: String, shopId: String, revenueRecordId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !revenueRecordId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.revenueRecord.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: revenueRecordId))
    }
    
    static func getExpensesCollection(userId: String, shopId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.expense.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    static func getExpenseDocument(userId: String, shopId: String, expenseId: String) -> String {
        guard !userId.isEmpty, !shopId.isEmpty, !expenseId.isEmpty else {
            return "Invalid"
        }
        return DatabaseCollection.expense.path(for: .deepNestedDocument(userId: userId, shopId: shopId, optionId: expenseId))
    }
}


