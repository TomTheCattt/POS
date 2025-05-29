import Foundation
import FirebaseFirestore
import Combine

final class DatabaseService: DatabaseServiceProtocol {
    static let shared = DatabaseService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Collection Operations
    func create<T: Codable>(_ item: T, in collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> String {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        let document = db.collection(path).document()
        try document.setData(from: item)
        return document.documentID
    }
    
    func update<T: Codable>(_ item: T, id: String, in collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> T {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        let document = db.collection(path).document(id)
        try document.setData(from: item)
        return item
    }
    
    func delete(id: String, from collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        try await db.collection(path).document(id).delete()
    }
    
    func get<T: Codable>(id: String, from collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> T {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        let snapshot = try await db.collection(path).document(id).getDocument()
        guard let data = try? snapshot.data(as: T.self) else {
            throw AppError.database(.decodingError)
        }
        return data
    }
    
    func getAll<T: Codable>(from collection: DatabaseCollection, type: DatabaseCollection.PathType) async throws -> [T] {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        let snapshot = try await db.collection(path).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    // MARK: - Query Operations
    func getAll<T>(from collection: DatabaseCollection, type: DatabaseCollection.PathType, queryBuilder: ((Query) -> Query)?) async throws -> [T] where T : Decodable, T : Encodable {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        var query: Query = db.collection(path)
        
        if let builder = queryBuilder {
            query = builder(query)
        }
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    // MARK: - Batch Operations
    func batchWrite<T: Codable>(
        _ items: [T],
        to collection: DatabaseCollection,
        type: DatabaseCollection.PathType
    ) async throws {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        let batch = db.batch()
        
        for item in items {
            let document = db.collection(path).document()
            try batch.setData(from: item, forDocument: document)
        }
        
        try await batch.commit()
    }
    
    func batchUpdate<T: Codable>(
        _ updates: [(id: String, item: T)],
        in collection: DatabaseCollection,
        type: DatabaseCollection.PathType
    ) async throws {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        let batch = db.batch()
        
        for update in updates {
            let document = db.collection(path).document(update.id)
            try batch.setData(from: update.item, forDocument: document)
        }
        
        try await batch.commit()
    }
    
    func batchDelete(
        _ ids: [String],
        from collection: DatabaseCollection,
        type: DatabaseCollection.PathType
    ) async throws {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        let batch = db.batch()
        
        for id in ids {
            let document = db.collection(path).document(id)
            batch.deleteDocument(document)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Real-time Updates
    func addListener<T: Codable>(
        collection: DatabaseCollection,
        type: DatabaseCollection.PathType,
        queryBuilder: ((Query) -> Query)?,
        completion: @escaping (Result<[T], Error>) -> Void
    ) -> ListenerRegistration? {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            completion(.failure(AppError.database(.invalidData)))
            return nil
        }
        
        var query: Query = db.collection(path)
        if let builder = queryBuilder {
            query = builder(query)
        }
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let items = documents.compactMap { try? $0.data(as: T.self) }
            completion(.success(items))
        }
        
        return listener
    }
    
    func addDocumentListener<T: Codable>(
        collection: DatabaseCollection,
        type: DatabaseCollection.PathType,
        id: String,
        completion: @escaping (Result<T?, Error>) -> Void
    ) -> ListenerRegistration? {
        let path = collection.path(for: type)
        
        guard !path.contains("Invalid") else {
            completion(.failure(AppError.database(.invalidData)))
            return nil
        }
        
        let listener = db.collection(path).document(id)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    completion(.success(nil))
                    return
                }
                
                do {
                    let data = try snapshot.data(as: T.self)
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            }
        
        return listener
    }
    
    // MARK: - Transaction
    func runTransaction<T>(_ updateBlock: @escaping (inout T.Type) -> Void) async throws {
        try await db.runTransaction { transaction, errorPointer in
            var value = T.self
            updateBlock(&value)
            return nil
        }
    }
}

// MARK: - Convenience Methods
extension DatabaseService {
    
    // MARK: - User Operations
    func createUser<T: Codable>(_ user: T) async throws -> String {
        return try await create(user, in: .users, type: .collection)
    }
    
    func getUser<T: Codable>(userId: String) async throws -> T {
        let snapshot = try await db.collection("users")
            .whereField("uid", isEqualTo: userId)
            .getDocuments()
        
        guard let document = snapshot.documents.first,
              let user = try? document.data(as: T.self) else {
            throw AppError.database(.documentNotFound)
        }
        
        return user
    }
    
    func updateUser<T: Codable>(_ user: T, userId: String) async throws -> T {
        return try await update(user, id: userId, in: .users, type: .collection)
    }
    
    func deleteUser<T: Codable>(_ user: T, userId: String) async throws {
        return try await delete(id: userId, from: .users, type: .collection)
    }
    
    // MARK: - Shop Operations
    func createShop<T: Codable>(_ shop: T, userId: String) async throws -> String {
        return try await create(shop, in: .shops, type: .subcollection(parentId: userId))
    }
    
    func getShop<T: Codable>(userId: String, shopId: String) async throws -> T {
        return try await get(id: shopId, from: .shops, type: .subcollection(parentId: userId))
    }
    
    func getAllShops<T: Codable>(userId: String) async throws -> [T] {
        return try await getAll(from: .shops, type: .subcollection(parentId: userId))
    }
    
    func updateShop<T: Codable>(_ shop: T, userId: String, shopId: String) async throws -> T {
        return try await update(shop, id: shopId, in: .shops, type: .subcollection(parentId: userId))
    }
    
    func deleteShop(userId: String, shopId: String) async throws {
        try await delete(id: shopId, from: .shops, type: .subcollection(parentId: userId))
    }
    
    // MARK: - Order Operations
    func createOrder<T: Codable>(_ order: T, userId: String, shopId: String) async throws -> String {
        return try await create(order, in: .orders, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getOrder<T: Codable>(userId: String, shopId: String, orderId: String) async throws -> T {
        return try await get(id: orderId, from: .orders, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getAllOrders<T: Codable>(userId: String, shopId: String) async throws -> [T] {
        return try await getAll(from: .orders, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func updateOrder<T: Codable>(_ order: T, userId: String, shopId: String, orderId: String) async throws -> T {
        return try await update(order, id: orderId, in: .orders, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func deleteOrder(userId: String, shopId: String, orderId: String) async throws {
        try await delete(id: orderId, from: .orders, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    // MARK: - Menu Operations
    func createMenuItem<T: Codable>(_ menuItem: T, userId: String, shopId: String) async throws -> String {
        return try await create(menuItem, in: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getMenuItem<T: Codable>(userId: String, shopId: String, menuItemId: String) async throws -> T {
        return try await get(id: menuItemId, from: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getAllMenuItems<T: Codable>(userId: String, shopId: String) async throws -> [T] {
        return try await getAll(from: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func updateMenuItem<T: Codable>(_ menuItem: T, userId: String, shopId: String, menuItemId: String) async throws -> T {
        return try await update(menuItem, id: menuItemId, in: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func deleteMenuItem(userId: String, shopId: String, menuItemId: String) async throws {
        try await delete(id: menuItemId, from: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    // MARK: - Inventory Operations
    func createInventoryItem<T: Codable>(_ inventoryItem: T, userId: String, shopId: String) async throws -> String {
        return try await create(inventoryItem, in: .inventory, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getInventoryItem<T: Codable>(userId: String, shopId: String, inventoryItemId: String) async throws -> T {
        return try await get(id: inventoryItemId, from: .inventory, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getAllInventoryItems<T: Codable>(userId: String, shopId: String) async throws -> [T] {
        return try await getAll(from: .inventory, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func updateInventoryItem<T: Codable>(_ inventoryItem: T, userId: String, shopId: String, inventoryItemId: String) async throws {
        let _ = try await update(inventoryItem, id: inventoryItemId, in: .inventory, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func deleteInventoryItem(userId: String, shopId: String, inventoryItemId: String) async throws {
        try await delete(id: inventoryItemId, from: .inventory, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    // MARK: - Real-time Listeners
    func listenToOrders<T: Codable>(
        userId: String,
        shopId: String,
        queryBuilder: ((Query) -> Query)? = nil,
        completion: @escaping (Result<[T], Error>) -> Void
    ) -> ListenerRegistration? {
        return addListener(
            collection: .orders,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func listenToMenuItems<T: Codable>(
        userId: String,
        shopId: String,
        queryBuilder: ((Query) -> Query)? = nil,
        completion: @escaping (Result<[T], Error>) -> Void
    ) -> ListenerRegistration? {
        return addListener(
            collection: .menu,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func listenToInventoryItems<T: Codable>(
        userId: String,
        shopId: String,
        queryBuilder: ((Query) -> Query)? = nil,
        completion: @escaping (Result<[T], Error>) -> Void
    ) -> ListenerRegistration? {
        return addListener(
            collection: .inventory,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
}
