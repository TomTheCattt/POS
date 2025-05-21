import Foundation
import FirebaseFirestore
import Combine

class DatabaseService: DatabaseServiceProtocol {
    private let db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    // MARK: - Generic CRUD Operations
    func create<T: Codable>(collection: DatabaseCollection, data: T) async throws -> String {
        let docRef = db.collection(collection.rawValue).document()
        try await docRef.setData(from: data, merge: true)
        return docRef.documentID
    }
    
    func get<T: Codable>(collection: DatabaseCollection, id: String) async throws -> T {
        let docRef = db.collection(collection.rawValue).document(id)
        let snapshot = try await docRef.getDocument()
        
        guard let data = try? snapshot.data(as: T.self) else {
            throw AppError.database(.documentNotFound)
        }
        
        return data
    }
    
    func getAll<T: Codable>(collection: DatabaseCollection,
                           queryBuilder: ((Query) -> Query)?) async throws -> [T] {
        var query: Query = db.collection(collection.rawValue)
        
        if let queryBuilder = queryBuilder {
            query = queryBuilder(query)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }
    
    func update<T: Codable>(collection: DatabaseCollection, id: String, data: T) async throws {
        let docRef = db.collection(collection.rawValue).document(id)
        try await docRef.setData(from: data, merge: true)
    }
    
    func delete(collection: DatabaseCollection, id: String) async throws {
        let docRef = db.collection(collection.rawValue).document(id)
        try await docRef.delete()
    }
    
    // MARK: - Query Operations
    func query<T: Codable>(collection: DatabaseCollection,
                          whereField: String,
                          isEqualTo: Any) async throws -> [T] {
        let snapshot = try await db.collection(collection.rawValue)
            .whereField(whereField, isEqualTo: isEqualTo)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }
    
    // MARK: - Batch Operations
    func batchWrite<T: Codable>(collection: DatabaseCollection, items: [T]) async throws {
        let batch = db.batch()
        let collectionRef = db.collection(collection.rawValue)
        
        for var item in items {
            let docRef = collectionRef.document()
            if var identifiable = item as? any DatabaseIdentifiable {
                identifiable.id = docRef.documentID
                item = identifiable as! T
            }
            try batch.setData(from: item, forDocument: docRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    func batchUpdate<T: Codable>(collection: DatabaseCollection,
                                updates: [(id: String, data: T)]) async throws {
        let batch = db.batch()
        let collectionRef = db.collection(collection.rawValue)
        
        for (id, data) in updates {
            let docRef = collectionRef.document(id)
            try batch.setData(from: data, forDocument: docRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    func batchDelete(collection: DatabaseCollection, ids: [String]) async throws {
        let batch = db.batch()
        let collectionRef = db.collection(collection.rawValue)
        
        for id in ids {
            let docRef = collectionRef.document(id)
            batch.deleteDocument(docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Subcollection Operations
    func createInSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                         parentId: String,
                                         subcollection: String,
                                         data: T) async throws -> String {
        let docRef = db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection)
            .document()
        
        try await docRef.setData(from: data, merge: true)
        return docRef.documentID
    }
    
    func getFromSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                        parentId: String,
                                        subcollection: String,
                                        id: String) async throws -> T {
        let docRef = db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection)
            .document(id)
        
        let snapshot = try await docRef.getDocument()
        
        guard let data = try? snapshot.data(as: T.self) else {
            throw AppError.database(.documentNotFound)
        }
        
        return data
    }
    
    func getAllFromSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                           parentId: String,
                                           subcollection: String,
                                           queryBuilder: ((Query) -> Query)?) async throws -> [T] {
        var query: Query = db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection)
        
        if let queryBuilder = queryBuilder {
            query = queryBuilder(query)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }
    
    func updateInSubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                         parentId: String,
                                         subcollection: String,
                                         id: String,
                                         data: T) async throws {
        let docRef = db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection)
            .document(id)
        
        try await docRef.setData(from: data, merge: true)
    }
    
    func deleteFromSubcollection(parentCollection: DatabaseCollection,
                               parentId: String,
                               subcollection: String,
                               id: String) async throws {
        let docRef = db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection)
            .document(id)
        
        try await docRef.delete()
    }
    
    func querySubcollection<T: Codable>(parentCollection: DatabaseCollection,
                                      parentId: String,
                                      subcollection: String,
                                      whereField: String,
                                      isEqualTo: Any) async throws -> [T] {
        let snapshot = try await db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection)
            .whereField(whereField, isEqualTo: isEqualTo)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }
    
    // MARK: - Real-time Updates
    func addListener<T: Codable>(collection: DatabaseCollection,
                                queryBuilder: ((Query) -> Query)?,
                                completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration {
        var query: Query = db.collection(collection.rawValue)
        
        if let queryBuilder = queryBuilder {
            query = queryBuilder(query)
        }
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            do {
                let items = try documents.compactMap { try $0.data(as: T.self) }
                completion(.success(items))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func addDocumentListener<T: Codable>(collection: DatabaseCollection,
                                        id: String,
                                        completion: @escaping (Result<T?, Error>) -> Void) -> ListenerRegistration {
        let docRef = db.collection(collection.rawValue).document(id)
        
        return docRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.success(nil))
                return
            }
            
            do {
                let item = try snapshot.data(as: T.self)
                completion(.success(item))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func addSubcollectionListener<T: Codable>(parentCollection: DatabaseCollection,
                                            parentId: String,
                                            subcollection: String,
                                            queryBuilder: ((Query) -> Query)?,
                                            completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration {
        var query: Query = db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection)
        
        if let queryBuilder = queryBuilder {
            query = queryBuilder(query)
        }
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            do {
                let items = try documents.compactMap { try $0.data(as: T.self) }
                completion(.success(items))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func removeListener(_ listener: Any) {
        if let registration = listener as? ListenerRegistration {
            registration.remove()
        }
    }
}

// MARK: - Encodable Extension
extension Encodable {
    var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
} 
