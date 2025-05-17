//
//  OrderService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 13/5/25.
//

import Foundation

final class OrderService: OrderServiceProtocol, ObservableObject {
    static let shared = OrderService()
    
    func deleteOrder(id: String) async throws {
        
    }
    
    func createOrder(order: Order) async throws {
        
    }
    
    func getOrders() async throws -> [Order] {
        return [Order(id: "", items: [OrderItem(id: UUID().uuidString, menuItemId: "1", quantity: 1, note: "", temprature: .hot, consumption: .stay)], createdAt: Date(), createdBy: "", totalAmount: 1, discount: 0, paymentMethod: .cash)]
    }
    
    func getOrderDetails(id: String) async throws -> Order {
        return Order(id: "", items: [OrderItem(id: UUID().uuidString, menuItemId: "1", quantity: 1, note: "", temprature: .hot, consumption: .stay)], createdAt: Date(), createdBy: "", totalAmount: 1, discount: 0, paymentMethod: .cash)
    }
}
