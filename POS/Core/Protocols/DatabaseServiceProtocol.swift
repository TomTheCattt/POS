import Foundation
import FirebaseFirestore
import Combine

protocol DatabaseServiceProtocol {
    // MARK: - Collection Operations
    func create<T: Codable>(_ item: T, in collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> String
    func update<T: Codable>(_ item: T, id: String, in collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> T
    func delete(id: String, from collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws
    func get<T: Codable>(id: String, from collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> T
    func getAll<T: Codable>(from collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> [T]
    
    // MARK: - Query Operations
    func getAll<T: Codable>(from collection: DatabaseCollection,
                           type: DatabaseCollection.PathType,
                           queryBuilder: ((Query) -> Query)?) async throws -> [T]
    
    // MARK: - Batch Operations
    func batchWrite<T: Codable>(_ items: [T], to collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws
    func batchUpdate<T: Codable>(_ updates: [(id: String, item: T)], in collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws
    func batchDelete(_ ids: [String], from collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws
    
    // MARK: - Real-time Updates
    func addListener<T: Codable>(collection: DatabaseCollection,
                                type: DatabaseCollection.PathType,
                                queryBuilder: ((Query) -> Query)?,
                                completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration?
    
    func addDocumentListener<T: Codable>(collection: DatabaseCollection,
                                        type: DatabaseCollection.PathType,
                                        id: String,
                                        completion: @escaping (Result<T?, Error>) -> Void) -> ListenerRegistration?
    
//    // MARK: - Convenience Methods
//    // User Operations
//    func createUser<T: Codable>(_ user: T) async throws -> T
//    func getUser<T: Codable>(userId: String) async throws -> T
//    func updateUser<T: Codable>(_ user: T, userId: String) async throws -> T
//    func deleteUser<T: Codable>(_ user: T, userId: String) async throws
//    
//    // Shop Operations
//    func createShop<T: Codable>(_ shop: T, userId: String) async throws -> T
//    func getShop<T: Codable>(userId: String, shopId: String) async throws -> T
//    func getAllShops<T: Codable>(userId: String) async throws -> [T]
//    func updateShop<T: Codable>(_ shop: T, userId: String, shopId: String) async throws -> T
//    func deleteShop(userId: String, shopId: String) async throws
//    
//    // Order Operations
//    func createOrder<T: Codable>(_ order: T, userId: String, shopId: String) async throws -> T
//    func getOrder<T: Codable>(userId: String, shopId: String, orderId: String) async throws -> T
//    func getAllOrders<T: Codable>(userId: String, shopId: String) async throws -> [T]
//    func updateOrder<T: Codable>(_ order: T, userId: String, shopId: String, orderId: String) async throws -> T
//    func deleteOrder(userId: String, shopId: String, orderId: String) async throws
//    
//    // Menu Operations
//    func createMenuItem<T: Codable>(_ menuItem: T, userId: String, shopId: String) async throws -> T
//    func getMenuItem<T: Codable>(userId: String, shopId: String, menuItemId: String) async throws -> T
//    func getAllMenuItems<T: Codable>(userId: String, shopId: String) async throws -> [T]
//    func updateMenuItem<T: Codable>(_ menuItem: T, userId: String, shopId: String, menuItemId: String) async throws -> T
//    func deleteMenuItem(userId: String, shopId: String, menuItemId: String) async throws
//    
//    // Inventory Operations
//    func createInventoryItem<T: Codable>(_ inventoryItem: T, userId: String, shopId: String) async throws -> T
//    func getInventoryItem<T: Codable>(userId: String, shopId: String, inventoryItemId: String) async throws -> T
//    func getAllInventoryItems<T: Codable>(userId: String, shopId: String) async throws -> [T]
//    func updateInventoryItem<T: Codable>(_ inventoryItem: T, userId: String, shopId: String, inventoryItemId: String) async throws -> T
//    func deleteInventoryItem(userId: String, shopId: String, inventoryItemId: String) async throws
//    
//    // Real-time Listeners
//    func listenToOrders<T: Codable>(userId: String,
//                                   shopId: String,
//                                   queryBuilder: ((Query) -> Query)?,
//                                   completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration?
//    
//    func listenToMenuItems<T: Codable>(userId: String,
//                                      shopId: String,
//                                      queryBuilder: ((Query) -> Query)?,
//                                      completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration?
//    
//    func listenToInventoryItems<T: Codable>(userId: String,
//                                           shopId: String,
//                                           queryBuilder: ((Query) -> Query)?,
//                                           completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration?
}

// MARK: - Helper Types
struct QueryFilter {
    let field: String
    let operation: FilterOperation
    let value: Any
    
    enum FilterOperation {
        case isEqualTo
        case isGreaterThan
        case isGreaterThanOrEqualTo
        case isLessThan
        case isLessThanOrEqualTo
        case arrayContains
        case arrayContainsAny
        case whereIn
        case whereNotIn
    }
}

struct OrderBy {
    let field: String
    let descending: Bool
}

// MARK: - Default Implementations
extension DatabaseServiceProtocol {
    func queryWithFilters<T: Codable>(collection: DatabaseCollection,
                                      type: DatabaseCollection.PathType,
                                    filters: [QueryFilter],
                                    orderBy: OrderBy? = nil) async throws -> [T] {
        return try await getAll(from: collection, type: type) { query in
            var finalQuery = query
            
            for filter in filters {
                switch filter.operation {
                case .isEqualTo:
                    finalQuery = finalQuery.whereField(filter.field, isEqualTo: filter.value)
                case .isGreaterThan:
                    finalQuery = finalQuery.whereField(filter.field, isGreaterThan: filter.value)
                case .isGreaterThanOrEqualTo:
                    finalQuery = finalQuery.whereField(filter.field, isGreaterThanOrEqualTo: filter.value)
                case .isLessThan:
                    finalQuery = finalQuery.whereField(filter.field, isLessThan: filter.value)
                case .isLessThanOrEqualTo:
                    finalQuery = finalQuery.whereField(filter.field, isLessThanOrEqualTo: filter.value)
                case .arrayContains:
                    finalQuery = finalQuery.whereField(filter.field, arrayContains: filter.value)
                case .arrayContainsAny:
                    finalQuery = finalQuery.whereField(filter.field, arrayContainsAny: filter.value as! [Any])
                case .whereIn:
                    finalQuery = finalQuery.whereField(filter.field, in: filter.value as! [Any])
                case .whereNotIn:
                    finalQuery = finalQuery.whereField(filter.field, notIn: filter.value as! [Any])
                }
            }
            
            if let orderBy = orderBy {
                finalQuery = finalQuery.order(by: orderBy.field, descending: orderBy.descending)
            }
            
            return finalQuery
        }
    }
} 
