import Foundation
import Combine
import FirebaseFirestore

final class OrderService: BaseService, OrderServiceProtocol {
    
    static let shared = OrderService()
    
    // MARK: - Publishers
    var ordersPublisher: AnyPublisher<[Order]?, Never> {
        $orders.eraseToAnyPublisher()
    }
    
    // MARK: - CRUD Operations
    func createOrder(_ order: Order) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("orders").document()
        try await docRef.setData(order.dictionary)
    }
    
    func updateOrder(_ order: Order) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        guard let orderId = order.id else {
            throw AppError.order(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("orders").document(orderId)
        try await docRef.setData(order.dictionary, merge: true)
    }
    
    func deleteOrder(_ order: Order) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        guard let orderId = order.id else {
            throw AppError.order(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("orders").document(orderId)
        try await docRef.delete()
    }
    
    func fetchOrders() async throws -> [Order] {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let snapshot = try await db.collection("users").document(userId).collection("shops").document(shopId).collection("orders").getDocuments()
        return snapshot.documents.compactMap { document in
            let order = try? document.data(as: Order.self)
            return order
        }
    }
    
    func fetchOrder(id: String) async throws -> Order {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let document = try await db.collection("users").document(userId).collection("shops").document(shopId).collection("orders").document(id).getDocument()
        
        guard let order = try? document.data(as: Order.self) else {
            throw AppError.order(.notFound)
        }
        
        return order
    }
    
    // MARK: - Order Management
    
    func calculateOrderTotal(_ order: Order) -> Double {
        let subTotal = order.items.reduce(0) { result, item in
            result + (item.price * Double(item.quantity))
        }
        let total = subTotal - order.discount
        return max(total, 0)
    }
    
    // MARK: - Search & Filter
    func getOrdersByDate(from: Date, to: Date) async throws -> [Order] {
        let orders = try await fetchOrders()
        return orders.filter { order in
            order.createdAt >= from && order.createdAt <= to
        }
    }
} 
