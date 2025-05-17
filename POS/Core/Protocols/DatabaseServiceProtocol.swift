import Foundation
import Combine

protocol DatabaseServiceProtocol {
    // Collection Operations
    func create<T: Codable>(_ item: T, in collection: String) async throws -> T
    func update<T: Codable>(_ item: T, id: String, in collection: String) async throws -> T
    func delete(id: String, from collection: String) async throws
    func get<T: Codable>(id: String, from collection: String) async throws -> T
    func getAll<T: Codable>(from collection: String) async throws -> [T]
    
    // Query Operations
    func query<T: Codable>(
        collection: String,
        whereField: String,
        isEqualTo: Any
    ) async throws -> [T]
    
    func query<T: Codable>(
        collection: String,
        whereField: String,
        isGreaterThan: Any
    ) async throws -> [T]
    
    func query<T: Codable>(
        collection: String,
        whereField: String,
        isLessThan: Any
    ) async throws -> [T]
    
    // Batch Operations
    func batchWrite<T: Codable>(_ items: [T], to collection: String) async throws
    func batchUpdate<T: Codable>(_ updates: [(id: String, item: T)], in collection: String) async throws
    func batchDelete(_ ids: [String], from collection: String) async throws
    
    // Real-time Updates
    func observeDocument<T: Codable>(
        id: String,
        in collection: String
    ) -> AnyPublisher<T?, Error>
    
    func observeCollection<T: Codable>(
        collection: String
    ) -> AnyPublisher<[T], Error>
    
    // Transaction
    func runTransaction<T>(_ updateBlock: @escaping (inout T) -> Void) async throws
} 