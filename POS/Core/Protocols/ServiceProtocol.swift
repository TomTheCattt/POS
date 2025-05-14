//
//  ServiceProtocol.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import UIKit

// MARK: - 1. Handle Auth Service
protocol AuthServiceProtocol {
    func login(email: String, password: String, completion: @escaping (Result<String, AppError>) -> Void)
    func registerAccount(email: String, password: String, displayName: String, shopName: String, completion: @escaping (Result<Void, AppError>) -> Void)
}


// MARK: - 2. Saving Real Time Data: Order, Menu, Inventory
protocol FirestoreServiceProtocol {
    func fetchMenuItems(completion: @escaping (Result<[MenuItem], AppError>) -> Void)
    func createOrder(_ order: Order, completion: @escaping (Result<Void, AppError>) -> Void)
    func updateInventoryItem(_ item: InventoryItem, completion: @escaping (Result<Void, AppError>) -> Void)
    func observeOrders(completion: @escaping (Result<[Order], AppError>) -> Void)
}

// MARK: - 3. Handle Crashlytics
protocol CrashlyticsServiceProtocol {
    func log(_ message: String)
    func record(error: Error)
    func setUserID(_ id: String)
}

// MARK: - 4. Cloud Functions: Handle income reports, complex server logic
protocol FunctionsServiceProtocol {
    // Report
    func generateDailyReport(completion: @escaping (Result<Void, AppError>) -> Void)
    func generateWeeklyReport(completion: @escaping (Result<Void, AppError>) -> Void)
    func generateMonthlyReport(completion: @escaping (Result<Void, AppError>) -> Void)
    
    // Bill
    func createPDFInvoice(for order: Order, completion: @escaping (Result<URL, AppError>) -> Void)
    
    // User behavior
    func logCustomEvent(name: String, params: [String: Any]?)
    func detectUnusualActivity(completion: @escaping (Result<Void, AppError>) -> Void)
    
    // Discount & Customer
    func validateDiscountCode(_ code: String, completion: @escaping (Result<Double, AppError>) -> Void)
    func applyLoyaltyPoints(userID: String, orderTotal: Double, completion: @escaping (Result<Double, AppError>) -> Void)
    
    // Backup Data
    func backupDatabaseSnapshot(completion: @escaping (Result<Void, AppError>) -> Void)
    
    // Cashier Management
    func resetCashierDisplayNames(completion: @escaping (Result<Void, AppError>) -> Void)
}

// MARK: - 5. Push Notification
protocol MessagingServiceProtocol {
    func requestNotificationPermission(completion: @escaping (Bool) -> Void)
    func subscribeToTopic(_ topic: String)
    func unsubscribeFromTopic(_ topic: String)
}

// MARK: - 6. Storage: Save image menu items, receipts...
protocol StorageServiceProtocol {
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<URL, AppError>) -> Void)
    func deleteImage(at path: String, completion: @escaping (Result<Void, AppError>) -> Void)
}

// MARK: - 7. Shop Service
protocol ShopServiceProtocol {
    func getShopDetails() async throws -> Shop
    func updateShop(shop: Shop) async throws -> Shop
}

// MARK: - 8. Order Service
protocol OrderServiceProtocol {
    func createOrder(items: [OrderItem]) async throws -> Order
    func getOrders() async throws -> [Order]
    func getOrderDetails(id: String) async throws -> Order
    func clearOrder()
}

// MARK: - 9. Inventory Service
protocol InventoryServiceProtocol {
    func getInventoryItems() async throws -> [InventoryItem]
    func getInventoryItem(id: String) async throws -> InventoryItem
    func updateInventoryItem(item: InventoryItem) async throws -> InventoryItem
    func addInventoryItem(item: InventoryItem) async throws -> InventoryItem
}

// MARK: - 10. Analytics Service
protocol AnalyticsServiceProtocol {
    func getDailySales() async throws -> [DailySales]
    func getTopSellingItems() async throws -> [TopSellingItem]
    func getRevenueReport(startDate: Date, endDate: Date) async throws -> RevenueReport
}

// MARK: - 11. Home Service
protocol HomeServiceProtocol {
    func logout()
}

protocol MenuServiceProtocol {
    func searchMenuItem()
    func updateMenuItem()
}

struct DailySales {
    let date: Date
    let totalSales: Double
    let orderCount: Int
}

struct TopSellingItem {
    let itemId: String
    let name: String
    let quantity: Int
    let revenue: Double
}

struct RevenueReport {
    let startDate: Date
    let endDate: Date
    let totalRevenue: Double
    let dailyRevenue: [Date: Double]
}
