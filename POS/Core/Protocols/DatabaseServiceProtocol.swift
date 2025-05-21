import Foundation
import FirebaseFirestore
import Combine

protocol DatabaseServiceProtocol {
    // MARK: - Generic CRUD Operations
    func create<T: Codable>(collection: DatabaseCollection, data: T) async throws -> String
    func get<T: Codable>(collection: DatabaseCollection, id: String) async throws -> T
    func update<T: Codable>(collection: DatabaseCollection, id: String, data: T) async throws
    func delete(collection: DatabaseCollection, id: String) async throws
    
    // MARK: - Query Operations
    func getAll<T: Codable>(collection: DatabaseCollection,
                           queryBuilder: ((Query) -> Query)?) async throws -> [T]
    
    func query<T: Codable>(collection: DatabaseCollection,
                          whereField: String,
                          isEqualTo: Any) async throws -> [T]
    
    func queryWithFilters<T: Codable>(collection: DatabaseCollection,
                                    filters: [QueryFilter],
                                    orderBy: OrderBy?) async throws -> [T]
    
    // MARK: - Batch Operations
    func batchWrite<T: Codable>(collection: DatabaseCollection,
                               items: [T]) async throws
    
    func batchUpdate<T: Codable>(collection: DatabaseCollection,
                                updates: [(id: String, data: T)]) async throws
    
    func batchDelete(collection: DatabaseCollection,
                    ids: [String]) async throws
    
    // MARK: - Subcollection Operations
    func createInSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                         parentId: String,
                                         subcollection: String,
                                         data: T) async throws -> String
    
    func getFromSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                        parentId: String,
                                        subcollection: String,
                                        id: String) async throws -> T
    
    func getAllFromSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                           parentId: String,
                                           subcollection: String,
                                           queryBuilder: ((Query) -> Query)?) async throws -> [T]
    
    func updateInSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                         parentId: String,
                                         subcollection: String,
                                         id: String,
                                         data: T) async throws
    
    func deleteFromSubcollection(parentCollection: DatabaseCollection,
                               parentId: String,
                               subcollection: String,
                               id: String) async throws
    
    func querySubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                      parentId: String,
                                      subcollection: String,
                                      whereField: String,
                                      isEqualTo: Any) async throws -> [T]
    
    // MARK: - Real-time Updates
    func addListener<T: Codable>(collection: DatabaseCollection,
                                queryBuilder: ((Query) -> Query)?,
                                completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration
    
    func addDocumentListener<T: Codable>(collection: DatabaseCollection,
                                        id: String,
                                        completion: @escaping (Result<T?, Error>) -> Void) -> ListenerRegistration
    
    func addSubcollectionListener<T: Codable>(parentCollection: DatabaseCollection,
                                            parentId: String,
                                            subcollection: String,
                                            queryBuilder: ((Query) -> Query)?,
                                            completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration
    
    func removeListener(_ listener: Any)
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
                                    filters: [QueryFilter],
                                    orderBy: OrderBy? = nil) async throws -> [T] {
        return try await getAll(collection: collection) { query in
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
