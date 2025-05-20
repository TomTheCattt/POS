//
//  ServiceProtocol.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import UIKit
import Combine

// MARK: - BaseService Protocol
protocol BaseServiceProtocol: ObservableObject {
    var currentUser: AppUser? { get }
    var selectedShop: Shop? { get }
    var menuItems: [MenuItem]? { get }
    var inventoryItems: [InventoryItem]? { get }
    var orders: [Order]? { get }
    var isLoading: Bool { get }
    var error: Error? { get }
}

// MARK: - 1. Handle Auth Service
protocol AuthServiceProtocol: BaseServiceProtocol {
    func login(email: String, password: String) async throws -> AppUser
    func registerAccount(email: String, password: String, displayName: String, shopName: String) async throws
    func logout() async throws
    func resetPassword(email: String) async throws
    func updatePassword(currentPassword: String, newPassword: String) async throws
    func deleteAccount(password: String) async throws
    func updateProfile(displayName: String?, photoURL: URL?) async throws
    func checkEmailVerification() async throws
    func sendEmailVerification() async throws
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
protocol ShopServiceProtocol: BaseServiceProtocol {
    // CRUD Operations
    func createShop(name: String, address: String) async throws -> Shop
    func updateShop(_ shop: Shop) async throws
    func deleteShop(_ shop: Shop) async throws
    func fetchShop(_ shop: Shop) async throws -> Shop
    
    // Shop Selection
    func selectShop(_ shop: Shop) throws
    var selectedShopPublisher: AnyPublisher<Shop?, Never> { get }
}

// MARK: - 8. Order Service
protocol OrderServiceProtocol: BaseServiceProtocol {
    // CRUD Operations
    func createOrder(_ order: Order) async throws
    func updateOrder(_ order: Order) async throws
    func deleteOrder(_ order: Order) async throws
    func fetchOrders() async throws -> [Order]
    func fetchOrder(id: String) async throws -> Order
    
    // Order Management
    func calculateOrderTotal(_ order: Order) -> Double
    
    // Search & Filter
    func getOrdersByDate(from: Date, to: Date) async throws -> [Order]
    
    // Publishers
    var ordersPublisher: AnyPublisher<[Order]?, Never> { get }
}

// MARK: - 9. Inventory Service
protocol InventoryServiceProtocol: BaseServiceProtocol {
    // CRUD Operations
    func createInventoryItem(_ item: InventoryItem) async throws
    func updateInventoryItem(_ item: InventoryItem) async throws
    func deleteInventoryItem(_ item: InventoryItem) async throws
    func fetchInventoryItems() async throws -> [InventoryItem]
    
    // Inventory Management
    func adjustQuantity(itemId: String, adjustment: Double) async throws
    func checkStock(itemId: String, requiredQuantity: Double) async throws -> Bool
    func getLowStockItems(threshold: Double) async throws -> [InventoryItem]
    
    // Publishers
    var inventoryItemsPublisher: AnyPublisher<[InventoryItem]?, Never> { get }
}

// MARK: - 10. Analytics Service
protocol AnalyticsServiceProtocol {
    // Sales Analytics
    func getDailySales(date: Date) async throws -> DailySales
    func getSalesReport(from: Date, to: Date) async throws -> SalesReport
    func getTopSellingItems(limit: Int) async throws -> [TopSellingItem]
    func getSalesTrend(period: AnalyticsPeriod) async throws -> [SalesTrendPoint]
    
    // Customer Analytics
    func getCustomerStats() async throws -> CustomerStats
    func getCustomerRetentionRate() async throws -> Double
    func getCustomerLifetimeValue() async throws -> Double
    
    // Product Analytics
    func getProductPerformance(productId: String) async throws -> ProductPerformance
    func getProductCategoryAnalytics() async throws -> [CategoryAnalytics]
    func getLowPerformingProducts(threshold: Double) async throws -> [ProductPerformance]
    
    // Employee Analytics
    func getEmployeePerformance(employeeId: String) async throws -> EmployeePerformance
    func getStaffEfficiencyReport() async throws -> StaffEfficiencyReport
    
    // Real-time Monitoring
    var currentDayStats: AnyPublisher<DailySales, Never> { get }
    var topSellingItemsPublisher: AnyPublisher<[TopSellingItem], Never> { get }
    
    // Custom Events
    //func logEvent(_ event: AnalyticsEvent)
    func getEventStats(eventName: String, from: Date, to: Date) async throws -> EventStats
}

//MARK: - 12. Menu Service
protocol MenuServiceProtocol: BaseServiceProtocol {
    // CRUD Operations
    func createMenuItem(_ item: MenuItem) async throws
    func updateMenuItem(_ item: MenuItem) async throws
    func deleteMenuItem(_ item: MenuItem) async throws
    func fetchMenuItems() async throws -> [MenuItem]
    
    // Batch Operations
    func createMenuItems(_ items: [MenuItem]) async throws
    
    // Search & Filter
    func searchMenuItems(query: String) async throws -> [MenuItem]
    func getMenuItemsByCategory(_ category: String) async throws -> [MenuItem]
    
    // Publishers
    var menuItemsPublisher: AnyPublisher<[MenuItem]?, Never> { get }
}

// MARK: - 13. Settings Service
protocol SettingsServiceProtocol {
    // Language
    var currentLanguage: AppLanguage { get }
    func setLanguage(_ language: AppLanguage)
    var languagePublisher: AnyPublisher<AppLanguage, Never> { get }
    
    // Theme
    var currentTheme: AppTheme { get }
    func setTheme(_ theme: AppTheme)
    var themePublisher: AnyPublisher<AppTheme, Never> { get }
    
    // Load & Save
    func loadSettings()
    func saveSettings()
}

//MARK: - 14. Printer Service
protocol PrinterServiceProtocol {
    
}

struct RevenueReport {
    let startDate: Date
    let endDate: Date
    let totalRevenue: Double
    let dailyRevenue: [Date: Double]
}
