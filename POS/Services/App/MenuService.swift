import Foundation
import Combine
import FirebaseFirestore

final class MenuService: BaseService, MenuServiceProtocol {
    
    static let shared = MenuService()
    
    // MARK: - Publishers
    var menuItemsPublisher: AnyPublisher<[MenuItem]?, Never> {
        $menuItems.eraseToAnyPublisher()
    }
    
    // MARK: - CRUD Operations
    func createMenuItem(_ item: MenuItem) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("menuItems").document()
        try await docRef.setData(item.dictionary)
    }
    
    func updateMenuItem(_ item: MenuItem) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        guard let itemId = item.id else {
            throw AppError.shop(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("menuItems").document(itemId)
        try await docRef.setData(item.dictionary, merge: true)
    }
    
    func deleteMenuItem(_ item: MenuItem) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        guard let itemId = item.id else {
            throw AppError.shop(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("menuItems").document(itemId)
        try await docRef.delete()
    }
    
    func fetchMenuItems() async throws -> [MenuItem] {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let snapshot = try await db.collection("users").document(userId).collection("shops").document(shopId).collection("menuItems").getDocuments()
        return snapshot.documents.compactMap { document in
            return try? document.data(as: MenuItem.self)
        }
    }
    
    // MARK: - Batch Operations
    func createMenuItems(_ items: [MenuItem]) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let batch = db.batch()
        
        for item in items {
            let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("menuItems").document()
            try batch.setData(from: item, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Search & Filter
    func searchMenuItems(query: String) async throws -> [MenuItem] {
        let items = try await fetchMenuItems()
        guard !query.isEmpty else { return items }
        
        return items.filter { item in
            item.name.localizedCaseInsensitiveContains(query) ||
            item.category.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getMenuItemsByCategory(_ category: String) async throws -> [MenuItem] {
        let items = try await fetchMenuItems()
        return items.filter { $0.category == category }
    }
} 
