import Foundation
import FirebaseFirestore
import Combine

class BaseRepository<T: Codable & Identifiable> {
    // MARK: - Properties
    let database: DatabaseService
    let collection: DatabaseCollection
    
    // MARK: - Initialization
    init(database: DatabaseService, collection: DatabaseCollection) {
        self.database = database
        self.collection = collection
    }
    
    // MARK: - CRUD Operations
    func create(_ item: T) async throws -> String {
        return try await database.create(collection: collection, data: item)
    }
    
    func get(id: String) async throws -> T {
        return try await database.get(collection: collection, id: id)
    }
    
    func getAll(queryBuilder: ((Query) -> Query)? = nil) async throws -> [T] {
        return try await database.getAll(collection: collection, queryBuilder: queryBuilder)
    }
    
    func update(_ item: T) async throws {
        guard let id = item.id as? String else {
            throw AppError.database(.invalidData)
        }
        try await database.update(collection: collection, id: id, data: item)
    }
    
    func delete(id: String) async throws {
        try await database.delete(collection: collection, id: id)
    }
    
    // MARK: - Query Operations
    func query(whereField: String, isEqualTo: Any) async throws -> [T] {
        return try await database.query(
            collection: collection,
            whereField: whereField,
            isEqualTo: isEqualTo
        )
    }
    
    func queryWithFilters(filters: [QueryFilter], orderBy: OrderBy? = nil) async throws -> [T] {
        return try await database.queryWithFilters(
            collection: collection,
            filters: filters,
            orderBy: orderBy
        )
    }
    
    // MARK: - Batch Operations
    func batchWrite(_ items: [T]) async throws {
        try await database.batchWrite(collection: collection, items: items)
    }
    
    func batchUpdate(_ updates: [(id: String, item: T)]) async throws {
        try await database.batchUpdate(
            collection: collection,
            updates: updates.map { ($0.id, $0.item) }
        )
    }
    
    func batchDelete(_ ids: [String]) async throws {
        try await database.batchDelete(collection: collection, ids: ids)
    }
    
    // MARK: - Real-time Updates
    func addListener(queryBuilder: ((Query) -> Query)? = nil,
                    completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration {
        return database.addListener(
            collection: collection,
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func addDocumentListener(id: String,
                           completion: @escaping (Result<T?, Error>) -> Void) -> ListenerRegistration {
        return database.addDocumentListener(
            collection: collection,
            id: id,
            completion: completion
        )
    }
    
    func removeListener(_ listener: Any) {
        database.removeListener(listener)
    }
}

// MARK: - Shop Repository Extension
extension BaseRepository {
    func createInShop(userId: String, shopId: String, item: T) async throws -> String {
        return try await database.createInSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: collection.rawValue,
            data: item
        )
    }
    
    func getFromShop(userId: String, shopId: String, id: String) async throws -> T {
        return try await database.getFromSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: collection.rawValue,
            id: id
        )
    }
    
    func getAllFromShop(userId: String, shopId: String,
                       queryBuilder: ((Query) -> Query)? = nil) async throws -> [T] {
        return try await database.getAllFromSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: collection.rawValue,
            queryBuilder: queryBuilder
        )
    }
    
    func updateInShop(userId: String, shopId: String, item: T) async throws {
        guard let id = item.id as? String else {
            throw AppError.database(.invalidData)
        }
        try await database.updateInSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: collection.rawValue,
            id: id,
            data: item
        )
    }
    
    func deleteFromShop(userId: String, shopId: String, id: String) async throws {
        try await database.deleteFromSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: collection.rawValue,
            id: id
        )
    }
    
    func queryInShop(userId: String, shopId: String,
                    whereField: String, isEqualTo: Any) async throws -> [T] {
        return try await database.querySubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: collection.rawValue,
            whereField: whereField,
            isEqualTo: isEqualTo
        )
    }
    
    func addShopListener(userId: String, shopId: String,
                        queryBuilder: ((Query) -> Query)? = nil,
                        completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration {
        return database.addSubcollectionListener(
            parentCollection: .users,
            parentId: userId,
            subcollection: collection.rawValue,
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
} 
