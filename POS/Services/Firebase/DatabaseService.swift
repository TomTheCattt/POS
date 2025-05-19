import Foundation
import FirebaseFirestore
import Combine

final class DatabaseService: DatabaseServiceProtocol {
    // MARK: - Singleton
    static let shared = DatabaseService()
    
    // MARK: - Dependencies
    private let firestore: Firestore
    private let crashlytics: CrashlyticsServiceProtocol
    
    // MARK: - Private Properties
    private var listeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        firestore: Firestore = .firestore(),
        crashlytics: CrashlyticsServiceProtocol = CrashlyticsService.shared
    ) {
        self.firestore = firestore
        self.crashlytics = crashlytics
    }
    
    // MARK: - Collection Operations
    func create<T: Codable>(_ item: T, in collection: String) async throws -> T {
        return try await withErrorHandling {
            let document = firestore.collection(collection).document()
            var itemWithId = item
            
            // Nếu item có trường id, cập nhật nó
            if var identifiable = item as? any DatabaseIdentifiable {
                identifiable.id = document.documentID
                itemWithId = identifiable as! T
            }
            
            try document.setData(from: itemWithId)
            return itemWithId
        }
    }
    
    func update<T: Codable>(_ item: T, id: String, in collection: String) async throws -> T {
        return try await withErrorHandling {
            let document = firestore.collection(collection).document(id)
            try document.setData(from: item, merge: true)
            return item
        }
    }
    
    func delete(id: String, from collection: String) async throws {
        try await withErrorHandling {
            try await firestore.collection(collection).document(id).delete()
        }
    }
    
    func get<T: Codable>(id: String, from collection: String) async throws -> T {
        return try await withErrorHandling {
            let snapshot = try await firestore.collection(collection).document(id).getDocument()
            
            guard let data = try? snapshot.data(as: T.self) else {
                throw AppError.database(.decodingError)
            }
            
            return data
        }
    }
    
    func getAll<T: Codable>(from collection: String) async throws -> [T] {
        return try await withErrorHandling {
            let snapshot = try await firestore.collection(collection).getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: T.self)
            }
        }
    }
    
    // MARK: - Query Operations
    func query<T: Codable>(
        collection: String,
        whereField: String,
        isEqualTo: Any
    ) async throws -> [T] {
        return try await withErrorHandling {
            let snapshot = try await firestore.collection(collection)
                .whereField(whereField, isEqualTo: isEqualTo)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: T.self)
            }
        }
    }
    
    func query<T: Codable>(
        collection: String,
        whereField: String,
        isGreaterThan: Any
    ) async throws -> [T] {
        return try await withErrorHandling {
            let snapshot = try await firestore.collection(collection)
                .whereField(whereField, isGreaterThan: isGreaterThan)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: T.self)
            }
        }
    }
    
    func query<T: Codable>(
        collection: String,
        whereField: String,
        isLessThan: Any
    ) async throws -> [T] {
        return try await withErrorHandling {
            let snapshot = try await firestore.collection(collection)
                .whereField(whereField, isLessThan: isLessThan)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: T.self)
            }
        }
    }
    
    // MARK: - Batch Operations
    func batchWrite<T: Codable>(_ items: [T], to collection: String) async throws {
        try await withErrorHandling {
            let batch = firestore.batch()
            
            for item in items {
                let document = firestore.collection(collection).document()
                try batch.setData(from: item, forDocument: document)
            }
            
            try await batch.commit()
        }
    }
    
    func batchUpdate<T: Codable>(_ updates: [(id: String, item: T)], in collection: String) async throws {
        try await withErrorHandling {
            let batch = firestore.batch()
            
            for update in updates {
                let document = firestore.collection(collection).document(update.id)
                try batch.setData(from: update.item, forDocument: document, merge: true)
            }
            
            try await batch.commit()
        }
    }
    
    func batchDelete(_ ids: [String], from collection: String) async throws {
        try await withErrorHandling {
            let batch = firestore.batch()
            
            for id in ids {
                let document = firestore.collection(collection).document(id)
                batch.deleteDocument(document)
            }
            
            try await batch.commit()
        }
    }
    
    // MARK: - Real-time Updates
    func observeDocument<T: Codable>(
        id: String,
        in collection: String
    ) -> AnyPublisher<T?, Error> {
        let subject = PassthroughSubject<T?, Error>()
        
        let listener = firestore.collection(collection).document(id)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    subject.send(nil)
                    return
                }
                
                do {
                    let data = try snapshot.data(as: T.self)
                    subject.send(data)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        // Lưu listener để có thể remove sau này
        listeners["\(collection)_\(id)"] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    func observeCollection<T: Codable>(
        collection: String
    ) -> AnyPublisher<[T], Error> {
        let subject = PassthroughSubject<[T], Error>()
        
        let listener = firestore.collection(collection)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    subject.send([])
                    return
                }
                
                do {
                    let items = try snapshot.documents.compactMap { document in
                        try document.data(as: T.self)
                    }
                    subject.send(items)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        // Lưu listener để có thể remove sau này
        listeners[collection] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Transaction
    func runTransaction<T>(_ updateBlock: @escaping (inout T.Type) -> Void) async throws {
        try await withErrorHandling {
            try await firestore.runTransaction { transaction, errorPointer in
                var value = T.self
                updateBlock(&value)
                return nil
            }
        }
    }
    
    // MARK: - Private Methods
    private func withErrorHandling<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            crashlytics.record(error: error)
            throw AppError.database(.writeFailed)
        }
    }
    
    deinit {
        // Cleanup all listeners
        listeners.values.forEach { $0.remove() }
    }
}

// MARK: - Supporting Types
protocol DatabaseIdentifiable {
    var id: String { get set }
}

extension DatabaseService {
    enum CollectionPath {
        static let users = "users"
        static let shops = "shops"
        static let orders = "orders"
        static let inventory = "inventory"
        static let menu = "menu"
        static let transactions = "transactions"
    }
} 
