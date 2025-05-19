//
//  ShopService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 13/5/25.
//

import Combine
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

final class ShopService: ShopServiceProtocol {
    
    static let shared = ShopService()
    
    // MARK: - Properties
    @Published private(set) var currentShop: Shop?
    var currentShopPublisher: AnyPublisher<Shop?, Never> {
        $currentShop.eraseToAnyPublisher()
    }
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupShopListener()
    }
    
    private func setupShopListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("shops")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening for shop updates: \(error)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    self?.currentShop = nil
                    return
                }
                
                do {
                    let shop = try document.data(as: Shop.self)
                    self?.currentShop = shop
                } catch {
                    print("Error decoding shop: \(error)")
                }
            }
    }
    
    // MARK: - Public Methods
    func createShop(name: String, address: String, ownerId: String) -> AnyPublisher<Shop, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            let shop = Shop(
                id: UUID().uuidString,
                shopName: name,
                createdAt: Date()
            )
            
            do {
                try self.db.collection("shops").document(shop.id)
                    .setData(from: shop)
                promise(.success(shop))
                self.currentShop = shop
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func updateShop(id: String, name: String?, address: String?) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            var updateData: [String: Any] = [:]
            if let name = name {
                updateData["name"] = name
            }
            if let address = address {
                updateData["address"] = address
            }
            
            self.db.collection("shops").document(id)
                .updateData(updateData) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        if var shop = self.currentShop {
                            if let name = name {
                                shop.shopName = name
                            }
                            self.currentShop = shop
                        }
                        promise(.success(()))
                    }
                }
        }.eraseToAnyPublisher()
    }
    
    func fetchShop(id: String) -> AnyPublisher<Shop, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            self.db.collection("shops").document(id)
                .getDocument { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let document = snapshot, document.exists,
                          let shop = try? document.data(as: Shop.self) else {
                        promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shop not found"])))
                        return
                    }
                    
                    self.currentShop = shop
                    promise(.success(shop))
                }
        }.eraseToAnyPublisher()
    }
    
    func deleteShop(id: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            self.db.collection("shops").document(id)
                .delete { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        if self.currentShop?.id == id {
                            self.currentShop = nil
                        }
                        promise(.success(()))
                    }
                }
        }.eraseToAnyPublisher()
    }
    
    func getShopDetails() async throws -> Shop {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AppError.auth(.userNotFound)
        }
        
        let snapshot = try await db.collection("shops")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw AppError.shop(.notFound)
        }
        
        do {
            return try document.data(as: Shop.self)
        } catch {
            throw AppError.shop(.decodingError)
        }
    }
    
    func updateShop(shop: Shop) async throws -> Shop {
        
        do {
            try db.collection("shops").document(shop.id).setData(from: shop)
            return shop
        } catch {
            throw AppError.shop(.updateFailed)
        }
    }
}


