import Foundation
import Combine
import FirebaseFirestore

final class ShopService: BaseService, ShopServiceProtocol {
    
    static let shared = ShopService()
    
    // MARK: - Publishers
    var selectedShopPublisher: AnyPublisher<Shop?, Never> {
        $selectedShop.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - CRUD Operations
    func createShop(name: String, address: String) async throws -> Shop {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        let shopId = UUID().uuidString
        
        let shop = Shop(
            id: shopId,
            shopName: name,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await db.collection("users").document(userId).collection("shops").document(shopId).setData(shop.dictionary)
        return shop
    }
    
    func updateShop(_ shop: Shop) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = shop.id else {
            throw AppError.shop(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId)
        try await docRef.setData([
            "id": shopId,
            "shopName": shop.shopName,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": Date()
        ])
    }
    
    func deleteShop(_ shop: Shop) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = shop.id else {
            throw AppError.shop(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId)
        try await docRef.delete()
    }
    
    func fetchShop(_ shop: Shop) async throws -> Shop {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = shop.id else {
            throw AppError.shop(.notFound)
        }
        
        let document = try await db.collection("users").document(userId).collection("shops").document(shopId).getDocument()
        guard var shop = try? document.data(as: Shop.self) else {
            throw AppError.auth(.userNotFound)
        }
        return shop
    }
} 
