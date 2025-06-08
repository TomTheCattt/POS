import Foundation
import FirebaseFirestore
import Combine

final class DatabaseService: DatabaseServiceProtocol {
    
    static let shared = DatabaseService()
    
    private let db = Firestore.firestore()
    
    private var listeners: [String: ListenerRegistration] = [:] {
        didSet {
            print("Current Listener: \(listeners)")
        }
    }
    
    private init() {}
    
    deinit {
        removeAllListeners()
    }
    
    private func removeAllListeners() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    private func storeListener(_ listener: ListenerRegistration, forKey key: String) {
        removeListener(forKey: key)
        listeners[key] = listener
    }
    
    func removeListener(forKey key: String) {
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
    }
    
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
        
        guard !path.isEmpty, !path.contains("Invalid") else {
            throw AppError.database(.invalidData)
        }
        
        do {
            let snapshot = try await db.collection(path).getDocuments()
            
            if snapshot.documents.isEmpty {
                print("ℹ️ No documents found at path: \(path)")
            }
            
            return snapshot.documents.compactMap { document in
                do {
                    return try document.data(as: T.self)
                } catch {
                    print("⚠️ Decode error for document \(document.documentID): \(error)")
                    return nil
                }
            }
        } catch {
            print("🔥 Firestore fetch error from \(path): \(error)")
            throw AppError.database(.readFailed)
        }
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
    func addCollectionListener<T: Codable>(
        collection: DatabaseCollection,
        type: DatabaseCollection.PathType,
        key: String,
        queryBuilder: ((Query) -> Query)? = nil,
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
        removeListener(forKey: key)
        
        let path = collection.path(for: type)
        guard !path.contains("Invalid") else {
            completion(.failure(AppError.database(.invalidData)))
            return
        }
        
        var query: Query = db.collection(path)
        if let builder = queryBuilder {
            query = builder(query)
        }
        
        let listener = query.addSnapshotListener(includeMetadataChanges: false) { snapshot, error in
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
        
        storeListener(listener, forKey: key)
    }
    
    func addDocumentListener<T: Codable>(
        collection: DatabaseCollection,
        type: DatabaseCollection.PathType,
        key: String,
        id: String,
        completion: @escaping (Result<T?, Error>) -> Void
    ) {
        removeListener(forKey: key)
        
        let path = collection.path(for: type)
        guard !path.contains("Invalid") else {
            completion(.failure(AppError.database(.invalidData)))
            return
        }
        
        let listener = db.collection(path).document(id)
            .addSnapshotListener(includeMetadataChanges: false) { snapshot, error in
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
        
        storeListener(listener, forKey: key)
    }
    
    // MARK: - Transaction
    func runTransaction(_ updateBlock: @escaping (Transaction) throws -> Any?) async throws {
        let _ = try await db.runTransaction { [weak self] transaction, errorPointer in
            guard self != nil else {
                errorPointer?.pointee = NSError(domain: "DatabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])
                return nil
            }
            
            do {
                return try updateBlock(transaction)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    // Tiện ích cho transaction
    func getIngredientUsageInTransaction(_ transaction: Transaction, userId: String, shopId: String, ingredientId: String) throws -> IngredientUsage {
        let path = DatabaseCollection.ingredientsUsage.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
        let docRef = db.collection(path).document(ingredientId)
        let document = try transaction.getDocument(docRef)
        
        guard let ingredient = try? document.data(as: IngredientUsage.self) else {
            throw AppError.database(.documentNotFound)
        }
        
        return ingredient
    }
    
    func updateIngredientUsageInTransaction(_ transaction: Transaction, ingredientUsage: IngredientUsage, userId: String, shopId: String) throws {
        let path = DatabaseCollection.ingredientsUsage.path(for: .nestedSubcollection(userId: userId, shopId: shopId))
        guard let id = ingredientUsage.id else { throw AppError.database(.invalidData) }
        
        let docRef = db.collection(path).document(id)
        try transaction.setData(from: ingredientUsage, forDocument: docRef)
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
    func createMenu<T: Codable>(_ menu: T, userId: String, shopId: String) async throws -> String {
        return try await create(menu, in: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getMenu<T: Codable>(userId: String, shopId: String, menuId: String) async throws -> T {
        return try await get(id: menuId, from: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getAllMenu<T: Codable>(userId: String, shopId: String) async throws -> [T] {
        return try await getAll(from: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func updateMenu<T: Codable>(_ menu: T, userId: String, shopId: String, menuId: String) async throws -> T {
        return try await update(menu, id: menuId, in: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func deleteMenu(userId: String, shopId: String, menuId: String) async throws {
        try await delete(id: menuId, from: .menu, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    // MARK: - Ingredients Usage Operations
    func createIngredientUsage<T: Codable>(_ IngredientUsage: T, userId: String, shopId: String) async throws -> String {
        return try await create(IngredientUsage, in: .ingredientsUsage, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getIngredientUsage<T: Codable>(userId: String, shopId: String, IngredientUsageId: String) async throws -> T {
        return try await get(id: IngredientUsageId, from: .ingredientsUsage, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getAllIngredientUsages<T: Codable>(userId: String, shopId: String) async throws -> [T] {
        return try await getAll(from: .ingredientsUsage, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func updateIngredientUsage<T: Codable>(_ ingredientsUsage: T, userId: String, shopId: String, ingredientsUsageId: String) async throws {
        let _ = try await update(ingredientsUsage, id: ingredientsUsageId, in: .ingredientsUsage, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func deleteIngredientUsage(userId: String, shopId: String, ingredientsUsageId: String) async throws {
        try await delete(id: ingredientsUsageId, from: .ingredientsUsage, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    // MARK: - Staffs Operations
    func createStaff<T: Codable>(_ staff: T, userId: String, shopId: String) async throws -> String {
        return try await create(staff, in: .staff, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getStaff<T: Codable>(userId: String, shopId: String, staffId: String) async throws -> T {
        return try await get(id: staffId, from: .staff, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func getAllStaffs<T: Codable>(userId: String, shopId: String) async throws -> [T] {
        return try await getAll(from: .staff, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func updateStaff<T: Codable>(_ staff: T, userId: String, shopId: String, staffId: String) async throws {
        let _ = try await update(staff, id: staffId, in: .staff, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    func deleteStaff(userId: String, shopId: String, staffId: String) async throws {
        try await delete(id: staffId, from: .staff, type: .nestedSubcollection(userId: userId, shopId: shopId))
    }
    
    // MARK: - Menu Items Operations
    func createMenuItem<T: Codable>(_ menuItem: T, userId: String, shopId: String, menuId: String) async throws -> String {
        return try await create(menuItem, in: .menuItems, type: .deepNestedSubCollection(userId: userId, shopId: shopId, optionId: menuId))
    }
    
    func getMenuItem<T: Codable>(userId: String, shopId: String, menuId: String, menuItemId: String) async throws -> T {
        return try await get(id: menuItemId, from: .menuItems, type: .deepNestedSubCollectionDocument(userId: userId, shopId: shopId, optionId: menuId, menuItemId: menuItemId))
    }
    
    func getAllMenuItems<T: Codable>(userId: String, shopId: String, menuId: String) async throws -> [T] {
        return try await getAll(from: .menuItems, type: .deepNestedSubCollection(userId: userId, shopId: shopId, optionId: menuId))
    }
    
    func updateMenuItem<T: Codable>(_ menuItem: T, userId: String, shopId: String, menuId: String, menuItemId: String) async throws {
        let _ = try await update(menuItem, id: menuId, in: .menuItems, type: .deepNestedSubCollectionDocument(userId: userId, shopId: shopId, optionId: menuId, menuItemId: menuItemId))
    }
    
    func deleteMenuItem(userId: String, shopId: String, menuId: String, menuItemId: String) async throws {
        try await delete(id: menuItemId, from: .menuItems, type: .deepNestedSubCollectionDocument(userId: userId, shopId: shopId, optionId: menuId, menuItemId: menuItemId))
    }
    
    // MARK: - Real-time Listeners
    
    func listenToCurrentUser<T: Codable>(userId: String, completion: @escaping (Result<T?, Error>) -> Void) {
        addDocumentListener(collection: .users, type: .document, key: "users_\(userId)", id: userId, completion: completion)
    }
    
    func removeCurrentUserListener(userId: String) {
        removeListener(forKey: "users_\(userId)")
    }
    
    func listenToShops<T: Codable>(userId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<[T], Error>) -> Void) {
        addCollectionListener(
            collection: .shops,
            type: .subcollection(parentId: userId),
            key: "shops_\(userId)",
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func removeShopsListener(userId: String) {
        removeListener(forKey: "shops_\(userId)")
    }
    
//    func listenToShop<T: Codable>(userId: String, shopId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<T?, Error>) -> Void) {
//        addDocumentListener(
//            collection: .shops,
//            type: .subcollection(parentId: userId),
//            key: "shop_\(userId)_\(shopId)",
//            id: shopId,
//            completion: completion
//        )
//    }
    
    func listenToOrders<T: Codable>(userId: String, shopId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<[T], Error>) -> Void) {
        addCollectionListener(
            collection: .orders,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            key: "orders_\(userId)_\(shopId)",
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func removeOrdersListener(userId: String, shopId: String) {
        removeListener(forKey: "orders_\(userId)_\(shopId)")
    }
    
    func listenToMenuCollection<T: Codable>(userId: String, shopId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<[T], Error>) -> Void) {
        addCollectionListener(
            collection: .menu,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            key: "menu_collection_\(userId)_\(shopId)",
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func removeMenuCollectionListener(userId: String, shopId: String) {
        removeListener(forKey: "menu_collection_\(userId)_\(shopId)")
    }
    
    func listenToMenuDocument<T: Codable>(userId: String, shopId: String, menuId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<T?, Error>) -> Void) {
        addDocumentListener(
            collection: .menu,
            type: .deepNestedDocument(userId: userId, shopId: shopId, optionId: menuId),
            key: "menu_document_\(userId)_\(shopId)_\(menuId)",
            id: menuId,
            completion: completion
        )
    }
    
    func removeMenuDocumentListener(userId: String, shopId: String, menuId: String) {
        removeListener(forKey: "menu_collection_\(userId)_\(shopId)_\(menuId)")
    }
    
    func listenToIngredients<T: Codable>(userId: String, shopId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<[T], Error>) -> Void) {
        addCollectionListener(
            collection: .ingredientsUsage,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            key: "ingredients_\(userId)_\(shopId)",
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func removeIngredientsListener(userId: String, shopId: String) {
        removeListener(forKey: "ingredients_\(userId)_\(shopId)")
    }
    
    func listenToMenuItems<T: Codable>(userId: String, shopId: String, menuId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<[T], Error>) -> Void) {
        addCollectionListener(
            collection: .menuItems,
            type: .deepNestedSubCollection(userId: userId, shopId: shopId, optionId: menuId),
            key: "menu_items_\(shopId)_\(menuId)",
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func removeMenuItemsListener(shopId: String, menuId: String) {
        removeListener(forKey: "menu_items_\(shopId)_\(menuId)")
    }
    
    func listenToStaffs<T: Codable>(userId: String, shopId: String, queryBuilder: ((Query) -> Query)? = nil, completion: @escaping (Result<[T], Error>) -> Void) {
        addCollectionListener(
            collection: .staff,
            type: .nestedSubcollection(userId: userId, shopId: shopId),
            key: "staffs_\(userId)_\(shopId)",
            queryBuilder: queryBuilder,
            completion: completion
        )
    }
    
    func removeStaffsListener(userId: String, shopId: String) {
        removeListener(forKey: "staffs_\(userId)_\(shopId)")
    }
}
